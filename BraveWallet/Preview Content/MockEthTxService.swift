// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore

#if DEBUG

class MockEthTxService: BraveWalletTxService {
  
  func gasEstimation1559(_ completion: @escaping (BraveWallet.GasEstimation1559?) -> Void) {
    completion(nil)
  }

  func nonce(forHardwareTransaction txMetaId: String, completion: @escaping (String?) -> Void) {
    completion(nil)
  }
  
  func transactionMessage(toSign coinType: BraveWallet.CoinType, txMetaId: String, completion: @escaping (String?) -> Void) {
    completion(nil)
  }
  
  func processHardwareSignature(_ txMetaId: String, v: String, r: String, s: String, completion: @escaping (Bool) -> Void) {
    completion(false)
  }
  
  func makeErc721Transfer(fromData from: String, to: String, tokenId: String, contractAddress: String, completion: @escaping (Bool, [NSNumber]) -> Void) {
    completion(false, [])
  }
  
  func addUnapprovedTransaction(_ txDataUnion: BraveWallet.TxDataUnion, from: String, completion: @escaping (Bool, String, String) -> Void) {
    completion(true, "txMetaId", "")
  }
  
  func addUnapproved1559Transaction(_ txData: BraveWallet.TxData1559, from: String, completion: @escaping (Bool, String, String) -> Void) {
    completion(true, "txMetaId", "")
  }
  
  func makeErc20TransferData(_ toAddress: String, amount: String, completion: @escaping (Bool, [NSNumber]) -> Void) {
    completion(true, .init())
  }
  
  func makeErc20ApproveData(_ spenderAddress: String, amount: String, completion: @escaping (Bool, [NSNumber]) -> Void) {
    completion(true, .init())
  }
  
  func approveTransaction(_ coinType: BraveWallet.CoinType, txMetaId: String, completion: @escaping (Bool) -> Void) {
  }
  
  func rejectTransaction(_ coinType: BraveWallet.CoinType, txMetaId: String, completion: @escaping (Bool) -> Void) {
  }
  
  func setGasPriceAndLimitForUnapprovedTransaction(_ txMetaId: String, gasPrice: String, gasLimit: String, completion: @escaping (Bool) -> Void) {
    completion(false)
  }
  
  func setGasFeeAndLimitForUnapprovedTransaction(_ txMetaId: String, maxPriorityFeePerGas: String, maxFeePerGas: String, gasLimit: String, completion: @escaping (Bool) -> Void) {
    completion(false)
  }
  
  func setDataForUnapprovedTransaction(_ txMetaId: String, data: [NSNumber], completion: @escaping (Bool) -> Void) {
    completion(false)
  }
  
  func setNonceForUnapprovedTransaction(_ txMetaId: String, nonce: String, completion: @escaping (Bool) -> Void) {
    completion(false)
  }
  
  func allTransactionInfo(_ coinType: BraveWallet.CoinType, from: String, completion: @escaping ([BraveWallet.TransactionInfo]) -> Void) {
    completion([])
  }
  
  func add(_ observer: BraveWalletTxServiceObserver) {
  }
  
  func speedupOrCancelTransaction(_ coinType: BraveWallet.CoinType, txMetaId: String, cancel: Bool, completion: @escaping (Bool, String, String) -> Void) {
    completion(false, "", "Error Message")
  }
  
  func retryTransaction(_ coinType: BraveWallet.CoinType, txMetaId: String, completion: @escaping (Bool, String, String) -> Void) {
    completion(false, "", "Error Message")
  }
  
  func reset() {
  }
}

#endif
