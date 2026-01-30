@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Flight Tp'
@Metadata.allowExtensions: true
define root view entity ZC_C_FLIGHTTP
  provider contract transactional_query
  as projection on ZR_C_FlightTP
{
  @Consumption.valueHelpDefinition: [{entity:{name: 'ZI_C_CarrierVH', element: 'CarrierId'}}] 
  key CarrierId,
  key ConnectionId,
  key FlightDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      Price,
      CurrencyCode,
      PlaneTypeId,
      SeatsMax,
      SeatsOccupied,
      AirlineName,
      OccupancyRate,
      OccupancyCriticality,
      @Consumption.valueHelpDefinition: [{entity:{name: 'ZI_C_AirportVH', element: 'AirportId'}}] 
      AirPortFromId,
      AirportFromName,
      @Consumption.valueHelpDefinition: [{entity:{name: 'ZI_C_AirportVH', element: 'AirportId'}}]
      AirportToId,
      AirportToName,
      @Consumption.valueHelpDefinition: [{entity:{name: 'ZI_C_AirportVH', element: 'AirportId'}}] 
      AirportFromDisplay,
      @Consumption.valueHelpDefinition: [{entity:{name: 'ZI_C_AirportVH', element: 'AirportId'}}] 
      AirportToDisplay,
      
  //    _Bookings._Connection.AirportName as AirportName,
      
      _Bookings : redirected to composition child ZC_C_BookingTP,
      CarrierImageUrl
}
