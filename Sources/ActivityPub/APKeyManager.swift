//
//  APKeyManager.swift
//
//
//  Created by Nikhil Nigade on 28/08/24.
//

import _CryptoExtras

public class ActivityPubKeyManager {
  /// Generates an ECDSA key pair and returns the public and private keys.
  public static func generateECDSAKeyPair() throws -> (privateKey: String, publicKey: String) {
    let privateKey = try _RSA.Signing.PrivateKey(keySize: .bits2048)
    let publicKey = privateKey.publicKey
    
    let privateKeyPEM = privateKey.pemRepresentation
    let publicKeyPEM = publicKey.pemRepresentation
    
    return (privateKey: privateKeyPEM, publicKey: publicKeyPEM)
  }
}
