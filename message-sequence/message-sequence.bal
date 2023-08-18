import ballerina/io;
import ballerina/http;

type S3Response record {|
    string x\-amz\-id;
    string x\-amz\-request\-id;
    string Date;
    string ETag;
|};

const uploadId = "EXAMPLEJZ6e0YupT2h66iePQCc9IEbYbDUy4RTpMeoSMLPRp8Z5o1u8feSRonpvnWsKKG35tI2LB9VDPiCgTy.Gq2VxQLYjrue4Nq.NBdqI";
final http:Client s3Client = check new ("http://coral.s3.us.amazonaws.com.balmock.io");

public function main() returns error? {

    // Reads file as stream containing 4kb chunk.
    stream<io:Block, io:Error?> fileStream = check io:fileReadBlocksAsStream("./resources/employee_names.txt", 4096);

    http:Request request = new;

    int partNumber = 1;
    check from io:Block chunk in fileStream
        do {
            request.setBinaryPayload(chunk);
            S3Response response = check s3Client->/uploadPart/[partNumber]/[uploadId].put(request);
            partNumber += 1;
            io:println(response);
        };
}
