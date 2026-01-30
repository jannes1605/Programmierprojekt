@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Connection'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZR_C_Connection as select from ZI_C_Connection
association [0..*] to ZR_C_BOOKINGTP as _Bookings on $projection.CarrierId = _Bookings.CarrierId and $projection.ConnectionId = _Bookings.ConnectionId
association [1..1] to /dmo/airport   as _AirportFrom on $projection.AirportFromId = _AirportFrom.airport_id
  association [1..1] to /dmo/airport   as _AirportTo   on $projection.AirportToId   = _AirportTo.airport_id
{
  key CarrierId,
  key ConnectionId, 
  AirportFromId,
  AirportToId,
  DepartureTime,
  ArrivalTime,
  
  _Bookings,
  _AirportFrom,
  _AirportTo,
  _AirportFrom.name as AirportFromName,
  _AirportTo.name as AirportToName
}
