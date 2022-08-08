 import Foundation
 
 func saveToKeychain(_ data: Data, _ service: String, _ account: String) -> Bool {
    let query = [
        kSecValueData: data,
        kSecClass: kSecClassGenericPassword,
        kSecAttrService: service,
        kSecAttrAccount: account,
        ] as CFDictionary
    
    var status = SecItemAdd(query, nil)
    if status == errSecDuplicateItem {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
            ] as CFDictionary
        
        let attributesToUpdate = [kSecValueData: data] as CFDictionary
        status = SecItemUpdate(query, attributesToUpdate)
    }
    
    return status == errSecSuccess
 }
 
 func loadFromKeychain(_ service: String, _ account: String) -> Data? {
    let query = [
        kSecAttrService: service,
        kSecAttrAccount: account,
        kSecClass: kSecClassGenericPassword,
        kSecReturnData: true
        ] as CFDictionary
    
    var result: AnyObject?
    SecItemCopyMatching(query, &result)
    return (result as? Data)
 }
 
 func toUtf8String(_ data: Data) -> String? {
    return String(data: data, encoding: .utf8)
 }
