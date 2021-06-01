// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'MpesaModels.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StkTransactionStatusQuery _$StkTransactionStatusQueryFromJson(
    Map<String, dynamic> json) {
  return StkTransactionStatusQuery(
      BusinessShortCode: json['BusinessShortCode'] as String,
      Password: json['Password'] as String,
      Timestamp: json['Timestamp'] as String,
      CheckoutRequestID: json['CheckoutRequestID'] as String);
}

Map<String, dynamic> _$StkTransactionStatusQueryToJson(
        StkTransactionStatusQuery instance) =>
    <String, dynamic>{
      'BusinessShortCode': instance.BusinessShortCode,
      'Password': instance.Password,
      'Timestamp': instance.Timestamp,
      'CheckoutRequestID': instance.CheckoutRequestID
    };

StkTransactionStatusQuerySuccess _$StkTransactionStatusQuerySuccessFromJson(
    Map<String, dynamic> json) {
  return StkTransactionStatusQuerySuccess(
      ResponseCode: json['ResponseCode'] as String,
      ResponseDescription: json['ResponseDescription'] as String,
      MerchantRequestID: json['MerchantRequestID'] as String,
      CheckoutRequestID: json['CheckoutRequestID'] as String,
      ResultCode: json['ResultCode'] as String,
      ResultDesc: json['ResultDesc'] as String);
}

Map<String, dynamic> _$StkTransactionStatusQuerySuccessToJson(
        StkTransactionStatusQuerySuccess instance) =>
    <String, dynamic>{
      'ResponseCode': instance.ResponseCode,
      'ResponseDescription': instance.ResponseDescription,
      'MerchantRequestID': instance.MerchantRequestID,
      'CheckoutRequestID': instance.CheckoutRequestID,
      'ResultCode': instance.ResultCode,
      'ResultDesc': instance.ResultDesc
    };

StkPushRequest _$StkPushRequestFromJson(Map<String, dynamic> json) {
  return StkPushRequest(
      BusinessShortCode: json['BusinessShortCode'] as String,
      Password: json['Password'] as String,
      Timestamp: json['Timestamp'] as String,
      TransactionType: json['TransactionType'] as String,
      Amount: json['Amount'] as String,
      PartyA: json['PartyA'] as String,
      PartyB: json['PartyB'] as String,
      PhoneNumber: json['PhoneNumber'] as String,
      CallBackURL: json['CallBackURL'] as String,
      AccountReference: json['AccountReference'] as String,
      TransactionDesc: json['TransactionDesc'] as String);
}

Map<String, dynamic> _$StkPushRequestToJson(StkPushRequest instance) =>
    <String, dynamic>{
      'BusinessShortCode': instance.BusinessShortCode,
      'Password': instance.Password,
      'Timestamp': instance.Timestamp,
      'TransactionType': instance.TransactionType,
      'Amount': instance.Amount,
      'PartyA': instance.PartyA,
      'PartyB': instance.PartyB,
      'PhoneNumber': instance.PhoneNumber,
      'CallBackURL': instance.CallBackURL,
      'AccountReference': instance.AccountReference,
      'TransactionDesc': instance.TransactionDesc
    };

StkPushRequestSuccess _$StkPushRequestSuccessFromJson(
    Map<String, dynamic> json) {
  return StkPushRequestSuccess(
      MerchantRequestID: json['MerchantRequestID'] as String,
      CheckoutRequestID: json['CheckoutRequestID'] as String,
      ResponseDescription: json['ResponseDescription'] as String,
      ResponseCode: json['ResponseCode'] as String,
      CustomerMessage: json['CustomerMessage'] as String);
}

Map<String, dynamic> _$StkPushRequestSuccessToJson(
        StkPushRequestSuccess instance) =>
    <String, dynamic>{
      'MerchantRequestID': instance.MerchantRequestID,
      'CheckoutRequestID': instance.CheckoutRequestID,
      'ResponseDescription': instance.ResponseDescription,
      'ResponseCode': instance.ResponseCode,
      'CustomerMessage': instance.CustomerMessage
    };
