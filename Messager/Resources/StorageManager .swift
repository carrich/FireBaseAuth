//
//  StorageManager .swift
//  Messager
//
//  Created by Ngoduc on 7/1/20.
//  Copyright © 2020 com.techmaster.D. All rights reserved.
//

import Foundation
import FirebaseStorage

final class StorageManager{
    static let shared = StorageManager()
    private let storage = Storage.storage().reference()
    
    public typealias UploadFictureCompletion = (Result<String,Error>) -> Void
    //MARK: - Upload picture to firebase storege and returns completion with url string to download
    public func uploadProfilePicture(with data: Data,
                                     fileName: String,
                                     completion: @escaping UploadFictureCompletion){
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: { metadata, error in
            guard error == nil else {
                //failed
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            self.storage.child("images/\(fileName)").downloadURL(completion: { url , error in
                guard let url = url else {
                    print("failed to download url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                print("download url return: \(urlString)")
                completion(.success(urlString))
            })
        })
        
    }
    
    public enum StorageErrors: Error {
        case failedToUpload
        case failedToGetDownloadUrl
    }
    public func downloadUrl(for path: String, completion: @escaping (Result<URL, Error>)-> Void){
        let reference = storage.child(path)
        reference.downloadURL(completion: { url , error in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            completion(.success(url))
        })
    }
}
