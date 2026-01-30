CLASS zgc_call_center_fraport_ag DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_last_minute,
        carrier_name        TYPE /dmo/carrier_name,
        carrier_id          TYPE /dmo/carrier_id,
        connection_id       TYPE /dmo/connection_id,
        flight_date         TYPE /dmo/flight_date,
        airport_from_id     TYPE /dmo/airport_from_id,
        airport_to_id       TYPE /dmo/airport_to_id,
        city_from           TYPE /dmo/city,
        city_to             TYPE /dmo/city,
        price               TYPE /dmo/flight_price,
        currency_code       TYPE /dmo/currency_code,
        seats_max           TYPE /dmo/plane_seats_max,
        seats_occupied      TYPE /dmo/plane_seats_occupied,
        price_eur           TYPE /dmo/flight_price,
        seats_free          TYPE i,
        occupancy_percent   TYPE decfloat34,
        days_until_flight   TYPE i,
        discount_percent    TYPE i,
        discount_reason     TYPE string,
        price_original_eur  TYPE /dmo/flight_price,
        price_discounted    TYPE /dmo/flight_price,
      END OF ty_last_minute.

    TYPES tt_last_minute TYPE STANDARD TABLE OF ty_last_minute WITH EMPTY KEY.

    METHODS get_last_minute_offers
      IMPORTING
        iv_max_price_eur  TYPE /dmo/flight_price
        iv_date_from      TYPE d
        iv_date_to        TYPE d
        iv_from_airport   TYPE /dmo/airport_from_id OPTIONAL
        iv_to_airport     TYPE /dmo/airport_to_id OPTIONAL
        iv_from_city      TYPE /dmo/city OPTIONAL
        iv_to_city        TYPE /dmo/city OPTIONAL
      RETURNING
        VALUE(rt_offers)  TYPE tt_last_minute.

    METHODS enhance_offer_data
      IMPORTING
        iv_max_price_eur TYPE /dmo/flight_price
      CHANGING
        ct_offer_list    TYPE tt_last_minute.

    METHODS calculate_discount
      IMPORTING
        iv_occupancy_percent TYPE decfloat34
        iv_seats_free        TYPE i
        iv_days_until_flight TYPE i
      EXPORTING
        ev_discount_percent  TYPE i
        ev_discount_reason   TYPE string.

    METHODS display_offer_list
      IMPORTING
        if_out        TYPE REF TO if_oo_adt_classrun_out
        it_offer_list TYPE tt_last_minute.

    METHODS convert_to_euro
      IMPORTING
        iv_amount            TYPE /dmo/flight_price
        iv_currency          TYPE /dmo/currency_code
      RETURNING
        VALUE(rv_amount_eur) TYPE /dmo/flight_price.

ENDCLASS.



CLASS zgc_call_center_fraport_ag IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    DATA lv_max_price_eur TYPE /dmo/flight_price VALUE '2000.00'.
    DATA lv_date_from     TYPE d VALUE '20260909'.
    DATA lv_date_to       TYPE d VALUE '20261015'.
    DATA lv_from_airport  TYPE /dmo/airport_from_id VALUE ''.
    DATA lv_to_airport    TYPE /dmo/airport_to_id VALUE ''.
    DATA lv_from_city     TYPE /dmo/city VALUE ''.
    DATA lv_to_city       TYPE /dmo/city VALUE ''.

    DATA lv_date_from_de  TYPE string.
    DATA lv_date_to_de    TYPE string.
    DATA lv_output        TYPE string.
    DATA lv_filter_info   TYPE string.

    lv_date_from_de = |{ lv_date_from+6(2) }.{ lv_date_from+4(2) }.{ lv_date_from+0(4) }|.
    lv_date_to_de = |{ lv_date_to+6(2) }.{ lv_date_to+4(2) }.{ lv_date_to+0(4) }|.

    lv_output = |Suche nach Last-Minute-Angeboten (Zeitraum: { lv_date_from_de } - { lv_date_to_de }, unter { lv_max_price_eur } EUR)|.

    IF lv_from_airport IS NOT INITIAL.
      lv_filter_info = | \| Von Flughafen: { lv_from_airport }|.
      lv_output = lv_output && lv_filter_info.
    ELSEIF lv_from_city IS NOT INITIAL.
      lv_filter_info = | \| Von Stadt: { lv_from_city }|.
      lv_output = lv_output && lv_filter_info.
    ENDIF.

    IF lv_to_airport IS NOT INITIAL.
      lv_filter_info = | \| Nach Flughafen: { lv_to_airport }|.
      lv_output = lv_output && lv_filter_info.
    ELSEIF lv_to_city IS NOT INITIAL.
      lv_filter_info = | \| Nach Stadt: { lv_to_city }|.
      lv_output = lv_output && lv_filter_info.
    ENDIF.

    out->write( lv_output ).
    out->write( '--------------------------------------------------------------------' ).

    DATA(lt_offers) = get_last_minute_offers(
      iv_max_price_eur = lv_max_price_eur
      iv_date_from     = lv_date_from
      iv_date_to       = lv_date_to
      iv_from_airport  = lv_from_airport
      iv_to_airport    = lv_to_airport
      iv_from_city     = lv_from_city
      iv_to_city       = lv_to_city
    ).

    IF lt_offers IS NOT INITIAL.
      enhance_offer_data(
        EXPORTING iv_max_price_eur = lv_max_price_eur
        CHANGING ct_offer_list = lt_offers
      ).
      display_offer_list(
        if_out        = out
        it_offer_list = lt_offers
      ).
    ELSE.
      out->write( |INFO: Keine passenden Last-Minute-Angebote für die angegebenen Kriterien gefunden.| ).
    ENDIF.

  ENDMETHOD.


  METHOD get_last_minute_offers.
    SELECT
           carr~name AS carrier_name,
           f~carrier_id,
           f~connection_id,
           f~flight_date,
           conn~airport_from_id,
           conn~airport_to_id,
           dep_ap~city AS city_from,
           arr_ap~city AS city_to,
           f~price,
           f~currency_code,
           f~seats_max,
           f~seats_occupied
        FROM /dmo/flight AS f
        INNER JOIN /dmo/connection AS conn ON
            f~carrier_id    = conn~carrier_id AND
            f~connection_id = conn~connection_id
        INNER JOIN /dmo/carrier AS carr ON
            f~carrier_id = carr~carrier_id
        INNER JOIN /dmo/airport AS dep_ap ON
            conn~airport_from_id = dep_ap~airport_id
        INNER JOIN /dmo/airport AS arr_ap ON
            conn~airport_to_id = arr_ap~airport_id
        WHERE f~flight_date >= @iv_date_from
          AND f~flight_date <= @iv_date_to
          AND f~seats_occupied < f~seats_max
          AND ( @iv_from_airport = '' OR conn~airport_from_id = @iv_from_airport )
          AND ( @iv_to_airport = '' OR conn~airport_to_id = @iv_to_airport )
          AND ( @iv_from_city = '' OR dep_ap~city = @iv_from_city )
          AND ( @iv_to_city = '' OR arr_ap~city = @iv_to_city )
        INTO TABLE @rt_offers.
  ENDMETHOD.


  METHOD convert_to_euro.
    DATA lv_exchange_rate TYPE decfloat34.

    CASE iv_currency.
      WHEN 'EUR'.
        lv_exchange_rate = '1.0000'.
      WHEN 'USD'.
        lv_exchange_rate = '0.9200'.
      WHEN 'GBP'.
        lv_exchange_rate = '1.1700'.
      WHEN 'JPY'.
        lv_exchange_rate = '0.0062'.
      WHEN 'CHF'.
        lv_exchange_rate = '1.0500'.
      WHEN 'SGD'.
        lv_exchange_rate = '0.6800'.
      WHEN 'AUD'.
        lv_exchange_rate = '0.6100'.
      WHEN 'CAD'.
        lv_exchange_rate = '0.6700'.
      WHEN OTHERS.
        lv_exchange_rate = '1.0000'.
    ENDCASE.

    rv_amount_eur = iv_amount * lv_exchange_rate.
  ENDMETHOD.


  METHOD calculate_discount.
    DATA lv_time_discount TYPE i VALUE 0.
    DATA lv_occupancy_discount TYPE i VALUE 0.
    DATA lv_time_reason TYPE string.
    DATA lv_occupancy_reason TYPE string.

    IF iv_days_until_flight <= 3.
      lv_time_discount = 35.
      lv_time_reason = 'Super Last-Minute (innerhalb 3 Tage)'.

    ELSEIF iv_days_until_flight <= 7.
      lv_time_discount = 25.
      lv_time_reason = 'Last-Minute (innerhalb 1 Woche)'.

    ELSEIF iv_days_until_flight <= 14.
      lv_time_discount = 15.
      lv_time_reason = 'Kurzfristige Buchung (innerhalb 2 Wochen)'.

    ELSEIF iv_days_until_flight <= 21.
      lv_time_discount = 8.
      lv_time_reason = 'Buchung innerhalb 3 Wochen'.
    ENDIF.

    IF iv_occupancy_percent <= 30.
      lv_occupancy_discount = 30.
      lv_occupancy_reason = 'Sehr geringe Auslastung'.

    ELSEIF iv_occupancy_percent <= 50.
      lv_occupancy_discount = 20.
      lv_occupancy_reason = 'Geringe Auslastung'.

    ELSEIF iv_occupancy_percent <= 70.
      lv_occupancy_discount = 10.
      lv_occupancy_reason = 'Moderate Auslastung'.

    ELSEIF iv_seats_free >= 100.
      lv_occupancy_discount = 15.
      lv_occupancy_reason = 'Viele freie Plätze verfügbar'.

    ELSEIF iv_seats_free >= 50.
      lv_occupancy_discount = 8.
      lv_occupancy_reason = 'Gute Verfügbarkeit'.
    ENDIF.

    IF lv_time_discount > 0 AND lv_occupancy_discount > 0.
      IF lv_time_discount >= lv_occupancy_discount.
        ev_discount_percent = lv_time_discount + ( lv_occupancy_discount / 2 ).
        ev_discount_reason = |{ lv_time_reason } + { lv_occupancy_reason }|.
      ELSE.
        ev_discount_percent = lv_occupancy_discount + ( lv_time_discount / 2 ).
        ev_discount_reason = |{ lv_occupancy_reason } + { lv_time_reason }|.
      ENDIF.

      IF ev_discount_percent > 50.
        ev_discount_percent = 50.
      ENDIF.

    ELSEIF lv_time_discount > 0.
      ev_discount_percent = lv_time_discount.
      ev_discount_reason = lv_time_reason.

    ELSEIF lv_occupancy_discount > 0.
      ev_discount_percent = lv_occupancy_discount.
      ev_discount_reason = lv_occupancy_reason.

    ELSE.
      ev_discount_percent = 0.
      ev_discount_reason = ''.
    ENDIF.

  ENDMETHOD.


  METHOD enhance_offer_data.
    DATA lt_filtered_offers TYPE tt_last_minute.
    DATA lv_today TYPE d.

    lv_today = cl_abap_context_info=>get_system_date( ).

    LOOP AT ct_offer_list ASSIGNING FIELD-SYMBOL(<ls_offer>).

      <ls_offer>-days_until_flight = <ls_offer>-flight_date - lv_today.

      <ls_offer>-price_original_eur = convert_to_euro(
        iv_amount   = <ls_offer>-price
        iv_currency = <ls_offer>-currency_code
      ).

      <ls_offer>-seats_free = <ls_offer>-seats_max - <ls_offer>-seats_occupied.

      IF <ls_offer>-seats_max > 0.
        <ls_offer>-occupancy_percent =
          ( CONV decfloat34( <ls_offer>-seats_occupied ) / CONV decfloat34( <ls_offer>-seats_max ) ) * 100.
      ELSE.
        <ls_offer>-occupancy_percent = 0.
      ENDIF.

      calculate_discount(
        EXPORTING
          iv_occupancy_percent = <ls_offer>-occupancy_percent
          iv_seats_free        = <ls_offer>-seats_free
          iv_days_until_flight = <ls_offer>-days_until_flight
        IMPORTING
          ev_discount_percent  = <ls_offer>-discount_percent
          ev_discount_reason   = <ls_offer>-discount_reason
      ).

      IF <ls_offer>-discount_percent > 0.
        <ls_offer>-price_discounted =
          <ls_offer>-price_original_eur * ( 1 - ( CONV decfloat34( <ls_offer>-discount_percent ) / 100 ) ).
        <ls_offer>-price_eur = <ls_offer>-price_discounted.
      ELSE.
        <ls_offer>-price_eur = <ls_offer>-price_original_eur.
        <ls_offer>-price_discounted = <ls_offer>-price_original_eur.
      ENDIF.

      IF <ls_offer>-price_eur < iv_max_price_eur.
        APPEND <ls_offer> TO lt_filtered_offers.
      ENDIF.

    ENDLOOP.

    ct_offer_list = lt_filtered_offers.

    SORT ct_offer_list BY price_eur ASCENDING.
  ENDMETHOD.


  METHOD display_offer_list.
    if_out->write( |Gefundene Last-Minute-Angebote ({ lines( it_offer_list ) }), sortiert nach Preis:| ).
    if_out->write( |** Alle Preise inkl. automatischer Last-Minute-Rabatte **| ).
    if_out->write( | | ).

    LOOP AT it_offer_list INTO DATA(ls_offer).
      DATA(lv_route) = |{ ls_offer-airport_from_id }-{ ls_offer-airport_to_id }|.
      DATA(lv_flight_number) = |{ ls_offer-carrier_id }{ ls_offer-connection_id }|.
      DATA(lv_flight_date) = |{ ls_offer-flight_date+6(2) }.{ ls_offer-flight_date+4(2) }.{ ls_offer-flight_date+0(4) }|.

      DATA(lv_occupancy_int) = CONV i( ls_offer-occupancy_percent ).

      if_out->write( |--------------------------------------------------------------------| ).
      if_out->write( |> Fluggesellschaft:  { ls_offer-carrier_name } ({ lv_flight_number })| ).
      if_out->write( |> Strecke:           { lv_route } ({ ls_offer-city_from } → { ls_offer-city_to })| ).
      if_out->write( |> Flugdatum:         { lv_flight_date }| ).

      IF ls_offer-discount_percent > 0.
        if_out->write( |> Originalpreis:     { ls_offer-price_original_eur DECIMALS = 2 } EUR| ).
        if_out->write( |> Rabatt:            { ls_offer-discount_percent }% ({ ls_offer-discount_reason })| ).
        if_out->write( |> Aktionspreis:      { ls_offer-price_discounted DECIMALS = 2 } EUR *** SONDERPREIS ***| ).
      ELSE.
        if_out->write( |> Preis:             { ls_offer-price_eur DECIMALS = 2 } EUR| ).
      ENDIF.

      if_out->write( |> Verfügbarkeit:     { ls_offer-seats_free } freie Plätze ({ lv_occupancy_int }% belegt)| ).

    ENDLOOP.

    if_out->write( |--------------------------------------------------------------------| ).
    if_out->write( | | ).
  ENDMETHOD.

ENDCLASS.
