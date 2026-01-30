@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking'
@Metadata.allowExtensions: true
define view entity ZC_C_BookingTP as projection on ZR_C_BOOKINGTP
{
  key TravelId,
  key BookingId,
  BookingDate,
  @Consumption.valueHelpDefinition: [{entity:{name: 'ZI_C_CustomerVH', element: 'CustomerId'}}]
  CustomerId,
  CarrierId,
  ConnectionId,
  FlightDate,
  FlightPrice,
  CurrencyCode,
  FirstName,
  LastName,
  @Consumption.valueHelpDefinition: [{entity:{name: 'ZI_C_SUPPLEMENTVH', element: 'SupplementId'}}]
  SupplementId,
  SupplementDescription,
  SupplementCategory,
 // _Supplements,
  
  _Flight : redirected to parent ZC_C_FLIGHTTP
}
