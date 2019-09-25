README
==============================================================================
This project presents how to expose a Spring boot service and a Ballerina service as a single API using WSO2 micro gateway (MGW). 

![Alt text](/resources/MGWDevFlow.png?raw=true "Optional Title")

## Pre-requisites

1.Download WSO2 Micro-gateway toolkit from https://wso2.com/api-management/api-microgateway/  and follow https://docs.wso2.com/display/MG301/Installation+Prerequisites#InstallationPrerequisites-MicrogatewayToolkit for installation.

2. Download WSO2 Micro-gateway runtime  from https://wso2.com/api-management/api-microgateway/  and follow https://docs.wso2.com/display/MG301/Installation+Prerequisites#InstallationPrerequisites-MicrogatewayRuntime for installation. For this demo, micro-gw runtime docker image will be used.

3. Download ballerina from https://ballerina.io/downloads/ and follow https://ballerina.io/learn/getting-started/#installing-ballerina for installation . For this demo ballerina - 0.991.0 version is used.

4. Install Docker, Kubernetes and kubectl.

5. Mysql Installation. (5.7 is used in this demo)

## Deploying book-search Ballerina micro-service in Kubernetes

1. Install Ballerina as per instructions in above section.You could check if the installation is done by running thecommand 'ballerina -v'. Copy MySQL JDBC driver to the BALLERINA_HOME/bre/lib folder, as Mysql is the database that is used. 

2. Checkout microservices/ballerina folder which comprises of the book-search ballerina service. In this service, we are fetching the data from a Mysql database deployed in docker.You could refer [1] on how to deploy Mysql in docker for Mac. Additionally you could find the db script (with the schema defined) as db-scripts/initializeDataBase.sql to create the necessary table. Alternatively you could pull the mysql docker image from https://cloud.docker.com/u/himasha91/repository/docker/himasha91/mgw_db with username:password himasha:himasha..

Please update mysql connector information under below annotation (host,port,username,password) to suit your configurations.

mysql:Client booksDB = new({

     host: "localhost", 
     
        port: 3306, 
        
        name: "bookstore",
        
        username: "*****",
        
        password: "******",
        
        dbOptions: { useSSL: false }
        
    });
 3. After all the updates, build the ballerina service by executing the below command.This will build the kubernetes deployment/service and all related artifacts and provide a command to deploy them in Kubernetes.

`ballerina build books_search_service.bal`

4. Execute the received command to deploy the artifacts in Kubernetes similar to below.

`kubectl apply -f /Users/himasha/Desktop/kubernetes/books_search_service`

5. Execute below command to check if the book-search service is exposed in Kubernetes.
  `kubectl get svc`

  sample result 
  
  books-search   NodePort    10.98.196.40    <none>        9090:30259/TCP   112m`

## Running the Spring boot miroservice for book-listing

We are returning static results in this demo, but you could update it to fetch from the database if needed.

1. Checkout microservices/Spring boot folder from the git repository.
2. Open the 'springbooksapp' project using an IDE such as Eclipse. 
3. Right click on the project and go to Run as-> Run Configurations and provide the goal as 'spring-boot:run' and apply to the project. This would expose the service in port 8080.

## Updating OpenAPI specification with backend service information

Checkout api-definitions folder of the github repository and open the 'fullbooklist.yaml'file. This is a standard OpenAPI 3.0 definition which you can easily create or generate from a swagger provider.This defines a bookstore API with two resources with paths; /books/list and /books/search/{query}.Following is the use of the vendor specific extensions we have defined.
 base path of the API

`x-wso2-basePath: /bookstore/v1`

backend endpoints.

Update the matching backend endpoint URLs (IP and PORT) in below location.If you deployed the book-search ballerina service in Kubernetes, you need to add the Node port value as the port. 

x-wso2-endpoints:

 - bookList:
 
    urls:
   
    - http://localhost:8080
   
 - bookSearch:

    urls:
   
    - http://IP:NodePort (port that is mapped to 9090)

resource endpoints
 From above general endpoint listing, we are mapping the related endpoint url through reference for each resource. 
 x-wso2-production-endpoints: "#/x-wso2-endpoints/bookList"
  
 x-wso2-production-endpoints: "#/x-wso2-endpoints/bookSearch"

## Create a micro-gateway project with MGW toolkit

We will be using the micro-gw toolkit to create a micro-gw project and build the API artifacts that we are going to expose. If you have followed the installation instructions for the toolkit you should be able to run these commands from anywhere.

  1. Go to a preferred folder of yours and create a micro-gateway project called bookstore with the following command.

  `micro-gw init bookstore` 

 This would create a project structure as below.

bookstore

  ├── api_definitions 
  
├── conf

│   └── deployment-config.toml

├── extensions

│   ├── extension_filter.bal

│   ├── startup_extension.bal

│   └── token_revocation_extension.bal

├── interceptors

├── policies.yaml

├── services

│   ├── authorize_endpoint.bal

│   ├── revoke_endpoint.bal

│   ├── token_endpoint.bal

│   └── user_info_endpoint.bal

└── target

    └── gen
    
  
  2.Copy the updated swagger definition (booklistAPI.yaml) to your newly created micro-gw project bookstore/api-definitions folder.This contains the bookstore API definition along with book-list and book-search resources defined. 

  3. Run below command to build the artifacts using micro-gw toolkit to expose your API. This would create an executable (.balx) file in the target folder which you can use as input to the micro-gw runtime. 

      `micro-gw build  bookstore`

## Expose the API with MGW runtime 

1. As mentioned before, you could expose this using the MGW binary as suggested in https://docs.wso2.com/display/MG301/Quick+Start+Guide+-+Binary. In this demo, we will use the MGW docker image instead. Execute below command, which would mount the created executable (.balx) to MGW docker image and run the container. Additionally we are exposing 9090 as the http port and 9095 as the https port of the MGW. 

`docker run -d -v <bookstore_project_target_path>:/home/exec/ -p 9095:9095 -p 9090:9090 -e project="bookstore"  wso2/wso2micro-gw:3.0.1`

 2. Execute 'docker ps' command, and a MGW container should be up and running.

## Test the API

 1. After the APIs are exposed via WSO2 API Microgateway, you can invoke the API with a valid JWT token or an opaque access token. In order to use JWT tokens, WSO2 API Microgateway should be presented with a JWT signed by a trusted OAuth2 service.For this demo you could set the following sample token by running below command through the terminal. Or else, you could use WSO2 API manager store to create a new token.

 `TOKEN=eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Ik5UQXhabU14TkRNeVpEZzNNVFUxWkdNME16RXpPREpoWldJNE5ETmxaRFUxT0dGa05qRmlNUSJ9.eyJhdWQiOiJodHRwOlwvXC9vcmcud3NvMi5hcGltZ3RcL2dhdGV3YXkiLCJzdWIiOiJhZG1pbiIsImFwcGxpY2F0aW9uIjp7ImlkIjoyLCJuYW1lIjoiSldUX0FQUCIsInRpZXIiOiJVbmxpbWl0ZWQiLCJvd25lciI6ImFkbWluIn0sInNjb3BlIjoiYW1fYXBwbGljYXRpb25fc2NvcGUgZGVmYXVsdCIsImlzcyI6Imh0dHBzOlwvXC9sb2NhbGhvc3Q6OTQ0M1wvb2F1dGgyXC90b2tlbiIsImtleXR5cGUiOiJQUk9EVUNUSU9OIiwic3Vic2NyaWJlZEFQSXMiOltdLCJjb25zdW1lcktleSI6Ilg5TGJ1bm9oODNLcDhLUFAxbFNfcXF5QnRjY2EiLCJleHAiOjM3MDMzOTIzNTMsImlhdCI6MTU1NTkwODcwNjk2MSwianRpIjoiMjI0MTMxYzQtM2Q2MS00MjZkLTgyNzktOWYyYzg5MWI4MmEzIn0=.b_0E0ohoWpmX5C-M1fSYTkT9X4FN--_n7-bEdhC3YoEEk6v8So6gVsTe3gxC0VjdkwVyNPSFX6FFvJavsUvzTkq528mserS3ch-TFLYiquuzeaKAPrnsFMh0Hop6CFMOOiYGInWKSKPgI-VOBtKb1pJLEa3HvIxT-69X9CyAkwajJVssmo0rvn95IJLoiNiqzH8r7PRRgV_iu305WAT3cymtejVWH9dhaXqENwu879EVNFF9udMRlG4l57qa2AaeyrEguAyVtibAsO0Hd-DFy5MW14S6XSkZsis8aHHYBlcBhpy2RqcP51xRog12zOb-WcROy6uvhuCsv-hje_41WQ==`

2. Test the API locally with below command. 

To test book-listing resource - `curl -X GET "https://IP:9095/bookstore/v1/books/list" -k -H "Authorization:Bearer $TOKEN"`
To test book-search resource with book ID -  `curl -X GET "https://IP:9095/bookstore/v1/books/search/1" -k -H "Authorization:Bearer $TOKEN"`

This process can be followed by the entire development team, where a single MGW project can be edited, rebuilt and exposed through the MGW.

In a potential CI process you could push this project to a source repository such as git and integrate a cotinuous build with CI server such as Jenkins.


[1] https://dzone.com/articles/docker-for-mac-mysql-setup
