//
//  FileUtil.swift
//  SwiftyDropboxSync
//
//  Created by Lacy Rhoades on 12/1/17.
//  Copyright © 2017 Lacy Rhoades. All rights reserved.
//

import Foundation

class FileUtil {
    @discardableResult class func writeData(_ data: Data, toFilePath: String) -> Bool {
        let _ = FileUtil.unlink(toFilePath)
        let manager = FileManager.default
        return manager.createFile(atPath: toFilePath, contents: data, attributes: [:])
    }
    
    class func data(fromPath: String) -> Data? {
        do {
            let url = URL(fileURLWithPath: fromPath)
            print("FileUtil", String(format: "Reading from %@", url.absoluteString))
            return try Data(contentsOf: url)
        } catch {
            print("FileUtil", String(format: "Trouble reading from file path: %@ Error message: %@", fromPath, error.localizedDescription))
            return nil
        }
    }
    
    class func parentDir(_ filepath: String) -> String? {
        if let parent = NSURL(string: filepath)?.deletingLastPathComponent?.absoluteString {
            return parent
        }
        return nil
    }
    
    class func touchFile(atPath: String) {
        let manager = FileManager.default
        
        manager.createFile(atPath: atPath, contents: nil, attributes: nil)
    }
    
    class func move(from: URL, to: URL) {
        let manager = FileManager.default
        do {
            try manager.moveItem(at: from, to: to)
        } catch {
            print("FileUtil", String(format: "Error moving from: %@ to: %@", from.path, to.path))
        }
    }
    
    class func cleanupOldItems(_ dirPath: String) {
        let manager = FileManager.default
        var contents: [String] = []
        
        do {
            contents = try manager.contentsOfDirectory(atPath: dirPath)
        } catch {
            print("Cleanup failed")
            print("Can't get contents of dir ", dirPath)
            do {
                print("Creating dir ".appending(dirPath))
                try manager.createDirectory(atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Could not create dir")
            }
            return
        }
        
        for file in contents {
            let filepath = String(format: "%@/%@", dirPath, file)
            do {
                try manager.removeItem(atPath: filepath)
                print("Removed old files: ", file)
            } catch {
                print("Trouble removing old file:", filepath)
            }
        }
    }
    
    class func mkdirUsingFile(_ fullFilePath: String) -> Bool {
        guard var dirPath = NSURL(string:fullFilePath)?.deletingLastPathComponent?.absoluteString else {
            print("FileUtil", "Could not get dirPath for: ".appending(fullFilePath))
            return false
        }
        
        dirPath.remove(at: dirPath.index(before: dirPath.endIndex))
        
        let manager = FileManager.default
        
        if manager.fileExists(atPath: dirPath) == false {
            do {
                try manager.createDirectory(atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("FileUtil", "Problem with creating directory")
                print("FileUtil", dirPath)
                print("FileUtil", error.localizedDescription)
                return false
            }
        }
        
        return true
    }
    
    @discardableResult class func unlink(_ path: String) -> Bool {
        if FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {
                return false
            }
        }
        
        return true
    }
    
    @discardableResult class func removeFile(atPath path: String) -> Bool {
        if FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {
                return false
            }
        }
        
        return true
    }
    
    class func fileExists(_ path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
    
    class func fileSize(_ path: String) -> String {
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: path)
            let size = String(describing: attr[FileAttributeKey.size])
            return size
        } catch {
            return "0"
        }
    }
    
}
