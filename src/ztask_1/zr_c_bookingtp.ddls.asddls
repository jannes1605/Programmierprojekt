@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking TP'
define view entity ZR_C_BOOKINGTP
  as select from ZI_C_BOOKING
  association        to parent ZR_C_FlightTP as _Flight          on  $projection.CarrierId    = _Flight.CarrierId
                                                                 and $projection.ConnectionId = _Flight.ConnectionId
                                                                 and $projection.FlightDate   = _Flight.FlightDate
  association [1..1] to /dmo/customer        as _Customer        on  $projection.CustomerId = _Customer.customer_id
  association [1..1] to /dmo/suppl_text      as _SupplementTexts on  $projection.SupplementId = _SupplementTexts.supplement_id
 // association [0..*] to ZR_C_Supplement as _Supplements on $projection.BookingId = _Supplements.BookingId

{
  key ZI_C_BOOKING.TravelId                   as TravelId,
  key ZI_C_BOOKING.BookingId                  as BookingId,
      ZI_C_BOOKING.BookingDate                as BookingDate,
      ZI_C_BOOKING.CustomerId                 as CustomerId,
      ZI_C_BOOKING.CarrierId                  as CarrierId,
      ZI_C_BOOKING.ConnectionId               as ConnectionId,
      ZI_C_BOOKING.FlightDate                 as FlightDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      currency_conversion(
       amount             => ZI_C_BOOKING.FlightPrice,
       source_currency    => ZI_C_BOOKING.CurrencyCode,
       target_currency    => cast('EUR' as abap.cuky),
       exchange_rate_date => $session.system_date,
       error_handling     => 'SET_TO_NULL'  ) as FlightPrice,

      cast('EUR' as abap.cuky)                as CurrencyCode,
      _Flight,
      _Customer,
      _Customer.first_name                    as FirstName,
      _Customer.last_name                     as LastName,
      SupplementId,
      _SupplementTexts.description as SupplementDescription,
   //   _Supplements,
      
      case when instr(_SupplementTexts.supplement_id, 'BV') > 0 then 'Beverage'
            when instr(_SupplementTexts.supplement_id, 'ML') > 0 then 'Meal'
            when instr(_SupplementTexts.supplement_id, 'LU') > 0 then 'Luggage'
            when instr(_SupplementTexts.supplement_id, 'EX') > 0 then 'Extra'
            else ''
            end as SupplementCategory


}
