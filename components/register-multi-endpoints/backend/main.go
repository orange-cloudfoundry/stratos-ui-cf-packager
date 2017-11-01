package main

import (
	"crypto/tls"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"github.com/SUSE/stratos-ui/components/app-core/backend/datastore"
	"github.com/SUSE/stratos-ui/components/app-core/backend/repository/cnsis"
	"github.com/SUSE/stratos-ui/components/app-core/backend/repository/interfaces"
	log "github.com/Sirupsen/logrus"
	"github.com/cloudfoundry-community/gautocloud"
	_ "github.com/cloudfoundry-community/gautocloud/connectors/databases/client/mysql"
	_ "github.com/cloudfoundry-community/gautocloud/connectors/databases/client/postgresql"
	"github.com/cloudfoundry-community/gautocloud/connectors/databases/dbtype"
	"github.com/cloudfoundry-community/gautocloud/connectors/generic"
	"github.com/cloudfoundry-community/gautocloud/loader"
	"github.com/satori/go.uuid"
	"io/ioutil"
	"net"
	"net/http"
	"net/url"
	"strings"
	"time"
)

var httpClient *http.Client
var transport *http.Transport

func init() {
	gautocloud.RegisterConnector(generic.NewConfigGenericConnector(CFMultipleEndpointsConfig{}))
	transport = &http.Transport{
		DialContext: (&net.Dialer{
			Timeout:   30 * time.Second,
			KeepAlive: 30 * time.Second,
			DualStack: true,
		}).DialContext,
		MaxIdleConns:          100,
		IdleConnTimeout:       90 * time.Second,
		TLSHandshakeTimeout:   10 * time.Second,
		ExpectContinueTimeout: 1 * time.Second,
		Proxy: http.ProxyFromEnvironment,
	}
	httpClient = &http.Client{
		Transport: transport,
	}
}

type CFInfo struct {
	AuthorizationEndpoint  string `json:"authorization_endpoint"`
	TokenEndpoint          string `json:"token_endpoint"`
	DopplerLoggingEndpoint string `json:"doppler_logging_endpoint"`
}
type CFMultipleEndpointsConfig struct {
	Endpoints []Endpoint
}
type Endpoint struct {
	Name              string `json:"name" cloud:"name"`
	CNSIType          string `json:"cnsi_type" cloud:"cnsi_type" cloud-default:"cf"`
	APIEndpoint       string `json:"api_endpoint" cloud:"api_endpoint"`
	SkipSSLValidation bool   `json:"skip_ssl_validation" cloud:"skip_ssl_validation"`
}
type CFMultipleEndpoints struct {
	portalProxy interfaces.PortalProxy
}

func Init(portalProxy interfaces.PortalProxy) (interfaces.StratosPlugin, error) {
	return &CFMultipleEndpoints{portalProxy: portalProxy}, nil
}

func (ch *CFMultipleEndpoints) GetMiddlewarePlugin() (interfaces.MiddlewarePlugin, error) {
	return nil, errors.New("Not implemented!")
}

func (ch *CFMultipleEndpoints) GetEndpointPlugin() (interfaces.EndpointPlugin, error) {
	return nil, errors.New("Not implemented!")
}

func (ch *CFMultipleEndpoints) GetRoutePlugin() (interfaces.RoutePlugin, error) {
	return nil, errors.New("Not implemented!")
}

func (ch *CFMultipleEndpoints) Init() error {
	if !gautocloud.IsInACloudEnv() {
		return nil
	}
	db, dbProvider, err := getDb()
	if err != nil {
		return err
	}
	if db == nil {
		return nil
	}
	cnsis.InitRepositoryProvider(dbProvider)
	cnsiRepo, err := cnsis.NewPostgresCNSIRepository(db)
	if err != nil {
		return err
	}
	var conf CFMultipleEndpointsConfig
	err = gautocloud.Inject(&conf)
	if err != nil {
		if _, ok := err.(loader.ErrGiveService); ok {
			return nil
		}
		return err
	}
	if len(conf.Endpoints) == 0 {
		return nil
	}
	entry := log.WithField("plugin", "register-multi-endpoints")
	for _, endpoint := range conf.Endpoints {
		entry.Debugf("Creating or updating endpoint %s ...", endpoint.Name)
		err = ch.addCnsi(cnsiRepo, endpoint)
		if err != nil {
			entry.Errorf("Could not register endpoint %s: %s", endpoint.Name, err.Error())
		}
		entry.Debugf("Finished creating endpoint %s.", endpoint.Name)
	}
	return nil
}
func (ch *CFMultipleEndpoints) addCnsi(cnsiRepo cnsis.Repository, endpoint Endpoint) error {
	if endpoint.Name == "" {
		return fmt.Errorf("Missing endpoint name")
	}
	if endpoint.APIEndpoint == "" {
		return fmt.Errorf("Missing endpoint url for %s.", endpoint.Name)
	}

	actualCnsi, err := cnsiRepo.FindByAPIEndpoint(endpoint.APIEndpoint)
	if err == nil {
		cnsiRepo.Delete(actualCnsi.GUID)
		return nil
	}

	transport.TLSClientConfig = &tls.Config{
		InsecureSkipVerify: endpoint.SkipSSLValidation,
	}
	resp, err := httpClient.Get(endpoint.APIEndpoint + "/v2/info")
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	var cfInfo CFInfo
	b, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return err
	}
	err = json.Unmarshal(b, &cfInfo)
	if err != nil {
		return err
	}
	apiEndpoint, err := url.Parse(strings.TrimSuffix(endpoint.APIEndpoint, "/"))
	if err != nil {
		return err
	}
	guid := uuid.NewV4().String()
	return cnsiRepo.Save(guid, interfaces.CNSIRecord{
		GUID:                   guid,
		Name:                   endpoint.Name,
		APIEndpoint:            apiEndpoint,
		CNSIType:               endpoint.CNSIType,
		SkipSSLValidation:      endpoint.SkipSSLValidation,
		AuthorizationEndpoint:  cfInfo.AuthorizationEndpoint,
		DopplerLoggingEndpoint: cfInfo.DopplerLoggingEndpoint,
		TokenEndpoint:          cfInfo.TokenEndpoint,
	})
}
func getDb() (*sql.DB, string, error) {
	var mysqlDb *dbtype.MysqlDB
	err := gautocloud.Inject(&mysqlDb)
	if err == nil {
		return mysqlDb.DB, datastore.MYSQL, nil
	}
	if _, ok := err.(loader.ErrGiveService); !ok {
		return nil, "", err
	}
	var postgresDb *dbtype.PostgresqlDB
	err = gautocloud.Inject(&mysqlDb)
	if err == nil {
		return postgresDb.DB, datastore.PGSQL, nil
	}
	if _, ok := err.(loader.ErrGiveService); !ok {
		return nil, "", err
	}
	return nil, "", nil
}
