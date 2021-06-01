import 'package:json_annotation/json_annotation.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart';

part 'MpesaModels.g.dart';

@JsonSerializable()
class StkTransactionStatusQuery {
  String BusinessShortCode;
  String Password;
  String Timestamp;
  String CheckoutRequestID;

  StkTransactionStatusQuery({this.BusinessShortCode, this.Password,
    this.Timestamp, this.CheckoutRequestID});

  factory StkTransactionStatusQuery.fromJson(Map<String,dynamic> json) => _$StkTransactionStatusQueryFromJson(json);

  Map<String,dynamic> toJson() => _$StkTransactionStatusQueryToJson(this);

  @override
  String toString() {
    return 'StkTransactionStatusQuery{_BusinessShortCode: $BusinessShortCode, _Password: $Password, _Timestamp: $Timestamp, _CheckoutRequestID: $CheckoutRequestID}';
  }


}

@JsonSerializable()
class StkTransactionStatusQuerySuccess {
  String ResponseCode;
  String ResponseDescription;
  String MerchantRequestID;
  String CheckoutRequestID;
  String ResultCode;
  String ResultDesc;

  StkTransactionStatusQuerySuccess({this.ResponseCode,
    this.ResponseDescription, this.MerchantRequestID,
    this.CheckoutRequestID, this.ResultCode, this.ResultDesc});

  factory StkTransactionStatusQuerySuccess.fromJson(Map<String,dynamic> json) => _$StkTransactionStatusQuerySuccessFromJson(json);

  Map<String,dynamic> toJson() => _$StkTransactionStatusQuerySuccessToJson(this);

  @override
  String toString() {
    return 'StkTransactionStatusQuerySuccess{_ResponseCode: $ResponseCode, _ResponseDescription: $ResponseDescription, _MerchantRequestID: $MerchantRequestID, _CheckoutRequestID: $CheckoutRequestID, _ResultCode: $ResultCode, _ResultDesc: $ResultDesc}';
  }
}

@JsonSerializable()
class StkPushRequest {
  String BusinessShortCode;
  String Password;
  String Timestamp;
  String TransactionType;
  String Amount;
  String PartyA;
  String PartyB;
  String PhoneNumber;
  String CallBackURL;
  String AccountReference;
  String TransactionDesc;

  StkPushRequest({this.BusinessShortCode, this.Password, this.Timestamp,
    this.TransactionType, this.Amount, this.PartyA, this.PartyB,
    this.PhoneNumber, this.CallBackURL, this.AccountReference,
    this.TransactionDesc});

  factory StkPushRequest.fromJson(Map<String,dynamic> json) => _$StkPushRequestFromJson(json);

  Map<String,dynamic> toJson() => _$StkPushRequestToJson(this);

  @override
  String toString() {
    return 'StkPushRequest{_BusinessShortCode: $BusinessShortCode, _Password: $Password, _Timestamp: $Timestamp, _TransactionType: $TransactionType, _Amount: $Amount, _PartyA: $PartyA, _PartyB: $PartyB, _PhoneNumber: $PhoneNumber, _CallBackURL: $CallBackURL, _AccountReference: $AccountReference, _TransactionDesc: $TransactionDesc}';
  }
}

@JsonSerializable()
class StkPushRequestSuccess{
  String MerchantRequestID;
  String CheckoutRequestID;
  String ResponseDescription;
  String ResponseCode;
  String CustomerMessage;

  StkPushRequestSuccess({this.MerchantRequestID, this.CheckoutRequestID,
    this.ResponseDescription, this.ResponseCode, this.CustomerMessage});

  factory StkPushRequestSuccess.fromJson(Map<String, dynamic> json) => _$StkPushRequestSuccessFromJson(json);

  Map<String,dynamic> toJson() => _$StkPushRequestSuccessToJson(this);

  @override
  String toString() {
    return 'StkPushRequestSuccess{_MerchantRequestID: $MerchantRequestID, _CheckoutRequestID: $CheckoutRequestID, _ResponseDescription: $ResponseDescription, _ResponseCode: $ResponseCode, _CustomerMessage: $CustomerMessage}';
  }
}