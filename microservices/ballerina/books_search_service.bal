
import ballerina/http;
import ballerina/log;
import ballerinax/kubernetes;
import ballerina/mysql;
import ballerina/sql;

// Create SQL client for MySQL database
mysql:Client booksDB = new({
     host: "localhost",
        port: 3306,
        name: "bookstore",
        username: "himasha",
        password: "himasha",
        dbOptions: { useSSL: false }
    });

@kubernetes:Service {
    name: "online-books-search",
    serviceType: "NodePort"
}
@kubernetes:Deployment {
    name:"online-books-search-deployment",
    image:"himasha91/onlinesearch:1.0.0",
}
@http:ServiceConfig {
    basePath: "/books"
}
service BookSearchService on new http:Listener(9090) {
    @http:ResourceConfig {
        methods:["GET"],
        path:"/search/{bookID}"
    }
    resource function search(http:Caller outboundEP, http:Request request,string bookID) {
       http:Response response = new;
       log:printInfo( bookID );
        // Convert the bookID string to integer
        var bkID = int.convert(bookID);
        if (bkID is int) {
            // Invoke retrieveById function to retrieve data from mysql database
            var bookData = retrieveById(bkID);
            // Send the response back to the client with the book data
            response.setPayload(untaint bookData);
        } else {
            response.statusCode = 400;
            response.setPayload("Error: bookID parameter should be a valid integer");
        }
        var respondRet = outboundEP->respond(response);
        if (respondRet is error) {
            // Log the error for the service maintainers.
            log:printError("Error responding to the client", err = respondRet);
        }
}
}

public function retrieveById(int bookID) returns (json) {
    json jsonReturnValue = {};
    string sqlString = "SELECT * FROM books WHERE bookID = ?";
    // Retrieve bookstore data by invoking select remote function defined in ballerina sql client
    var ret = booksDB->select(sqlString, (), bookID);
    if (ret is table<record {}>) {
        // Convert the sql data table into JSON using type conversion
        var jsonConvertRet = json.convert(ret);
        if (jsonConvertRet is json) {
            jsonReturnValue = jsonConvertRet;
        } else {
            jsonReturnValue = { "Status": "Data Not Found", "Error": "Error occurred in data conversion" };
            log:printError("Error occurred in data conversion", err = jsonConvertRet);
        }
    } else {
        jsonReturnValue = { "Status": "Data Not Found", "Error": "Error occurred in data retrieval" };
        log:printError("Error occurred in data retrieval", err = ret);
    }
    return jsonReturnValue;

}