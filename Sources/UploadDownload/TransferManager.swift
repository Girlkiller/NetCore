//
//  File.swift
//  NetCore
//
//  Created by feng qiu on 2026/3/14.
//

import Foundation
import Alamofire

public final class TransferManager {

    public static let shared = TransferManager()

}

public extension TransferManager {

    func upload(
        data:Data,
        to url:String,
        progress:@escaping (Double)->Void
    ) async throws -> Data {

        let request = AF.upload(data, to:url)

        request.uploadProgress {

            progress($0.fractionCompleted)

        }

        let response = await request.serializingData().response

        switch response.result {

        case .success(let data):

            return data

        case .failure(let error):

            throw error

        }

    }

}

public extension TransferManager {

    func download(
        _ url:String,
        progress:@escaping (Double)->Void
    ) async throws -> URL {

        let destination = DownloadRequest.suggestedDownloadDestination()

        let request = AF.download(url,to:destination)

        request.downloadProgress {

            progress($0.fractionCompleted)

        }

        let response = await request.serializingDownloadedFileURL().response

        switch response.result {

        case .success(let fileURL):

            return fileURL

        case .failure(let error):

            throw error

        }

    }

}
