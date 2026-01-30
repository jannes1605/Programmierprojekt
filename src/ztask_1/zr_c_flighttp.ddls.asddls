@AbapCatalog.viewEnhancementCategory: [ #NONE ]

@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Flight'

define root view entity ZR_C_FlightTP
  as select from ZI_C_Flights
  composition [0..*] of ZR_C_BOOKINGTP as _Bookings
    
  association [1..1] to /dmo/carrier   as _Carrier on $projection.CarrierId = _Carrier.carrier_id
  association [1..1] to /dmo/airport   as _AirportFrom on  $projection.AirPortFromId = _AirportFrom.airport_id
  association [1..1] to /dmo/airport   as _AirportTo   on  $projection.AirportToId = _AirportTo.airport_id

{

  key CarrierId,
  key ConnectionId,
  key FlightDate,
      Price,
      CurrencyCode,
      PlaneTypeId,
      SeatsMax,
      SeatsOccupied,
      case when OccupancyRate >= 80 then 1
               when OccupancyRate >= 40 then 2
               when OccupancyRate >= 0 then 3
               else 0
          end       as OccupancyCriticality,

      concat( cast( OccupancyRate as abap.char(6)), '%') as OccupancyRate,  
      _Bookings,
      _Carrier.name as AirlineName,
      AirPortFromId,
      AirportToId,
      _AirportFrom,
      _AirportTo,
      _AirportFrom.name     as AirportFromName,
      _AirportTo.name     as AirportToName,
      
      concat_with_space( _AirportFrom.name, concat( ' (', concat( AirPortFromId, ')') ),1 ) as AirportFromDisplay,
      
      concat_with_space( _AirportTo.name, concat( ' (', concat( AirportToId, ')') ),1 ) as AirportToDisplay,
      CarrierImageUrl
      
}
where FlightDate >= $session.system_date
