@AbapCatalog.viewEnhancementCategory: [ #NONE ]

@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Flights'

define view entity ZI_C_Flights
  as select from /dmo/flight
  association [1..*] to /dmo/connection as _Connections on $projection.ConnectionId = _Connections.connection_id

{
  key carrier_id                                                       as CarrierId,
  key connection_id                                                    as ConnectionId,
  key flight_date                                                      as FlightDate,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      currency_conversion(amount             => price,
                          source_currency    => currency_code,
                          target_currency    => cast('EUR' as abap.cuky),
                          exchange_rate_date => $session.system_date)  as Price,

      currency_code                                                    as CurrencyCode,
      plane_type_id                                                    as PlaneTypeId,
      seats_max                                                        as SeatsMax,
      seats_occupied                                                   as SeatsOccupied,

     case
        when seats_max = 0 then 0
        else cast((seats_occupied / seats_max) * 100 as abap.dec( 4, 0 )) end as OccupancyRate,
      _Connections.airport_from_id                                     as AirPortFromId,
      _Connections.airport_to_id                                       as AirportToId,
      @Semantics.imageUrl: true
      case carrier_id
      when 'AA' then 'https://cdn.aptoide.com/imgs/d/f/a/dfa1f84256c1410ca99ac7bf548ed7e6_icon.png'
      when 'AC' then 'https://companieslogo.com/img/orig/AC.TO-01622528.png?t=1720244490'
      when 'AF' then 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Air_France_logo_%281976-1990%29.svg/1280px-Air_France_logo_%281976-1990%29.svg.png'
      when 'AZ' then 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a9/Alitalia_Logo_2017%E2%80%932021.svg/3840px-Alitalia_Logo_2017%E2%80%932021.svg.png'
      when 'BA' then 'https://img.icons8.com/color/1200/british-airways.jpg'
      when 'CO' then 'https://news.gtp.gr/wp-content/uploads/2018/01/Cobalt-Air-logo.jpg'
      when 'DL' then 'https://deltamuseum.org/images/site/research/delta-brand/logos/16-9-logos/1962to1993_delta_logo.webp?sfvrsn=c7d656cf_1'
      when 'FJ' then ''
      when 'JL' then 'https://play-lh.googleusercontent.com/HmFickfWrOnPNIayhuFn9F1MQLzLQG7l9aElCpqVxs0FBGqA5AlzKOiMgwdhoS7seQ'
      when 'LH' then 'https://img.icons8.com/external-tal-revivo-shadow-tal-revivo/1200/external-lufthansa-is-the-largest-german-airline-which-automotive-shadow-tal-revivo.jpg'
      when 'NG' then ''
      when 'QF' then ''
      when 'SA' then ''
      when 'SQ' then 'https://cdn.freebiesupply.com/logos/large/2x/singapore-airlines-logo-png-transparent.png'
      when 'SR' then ''
      when 'UA' then 'https://play-lh.googleusercontent.com/ksMkNKYrH89qrIvuoLOtgElqPqjFMyHaWStkTTZGqWMCymFI6FW3uwyuLWyZxlVgwXc'
      else '/sap/bc/ui5_ui5/sap/flights/images/default.png'
      end                                                              as CarrierImageUrl
}
