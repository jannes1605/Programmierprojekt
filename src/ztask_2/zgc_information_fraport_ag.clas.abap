CLASS zgc_information_fraport_ag DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    " Datenstruktur für die allgemeine Flugsuche
    TYPES:
      BEGIN OF ty_flight_details,
        carrier_id             TYPE /dmo/carrier_id,
        connection_id          TYPE /dmo/connection_id,
        carrier_name           TYPE /dmo/carrier_name,
        flight_date            TYPE /dmo/flight_date,
        departure_city         TYPE /dmo/city,
        arrival_city           TYPE /dmo/city,
        departure_time         TYPE /dmo/flight_departure_time,
        arrival_time           TYPE /dmo/flight_arrival_time,
        price                  TYPE /dmo/flight_price,
        currency_code          TYPE /dmo/currency_code,
        seats_available        TYPE /dmo/plane_seats_max,
        departure_airport_id   TYPE /dmo/airport_id,
        departure_airport_name TYPE /dmo/airport_name,
        departure_country      TYPE land1,
        arrival_airport_id     TYPE /dmo/airport_id,
        arrival_airport_name   TYPE /dmo/airport_name,
        arrival_country        TYPE land1,
        flight_duration_text   TYPE string,
        availability_status    TYPE string,
      END OF ty_flight_details.

    TYPES tt_flight_details TYPE STANDARD TABLE OF ty_flight_details WITH EMPTY KEY.

    " Datenstruktur für die Passagier-spezifische Flugsuche
    TYPES:
      BEGIN OF ty_booking_details,
        customer_id     TYPE /dmo/customer_id,
        first_name      TYPE /dmo/first_name,
        last_name       TYPE /dmo/last_name,
        booking_id      TYPE /dmo/booking_id,
        carrier_name    TYPE /dmo/carrier_name,
        carrier_id      TYPE /dmo/carrier_id,
        connection_id   TYPE /dmo/connection_id,
        flight_date     TYPE /dmo/flight_date,
        departure_city  TYPE /dmo/city,
        arrival_city    TYPE /dmo/city,
        departure_time  TYPE /dmo/flight_departure_time,
        arrival_time    TYPE /dmo/flight_arrival_time,
        booking_status  TYPE /dmo/booking_status, " N=New, B=Booked, X=Cancelled
      END OF ty_booking_details.

    TYPES tt_booking_details TYPE STANDARD TABLE OF ty_booking_details WITH EMPTY KEY.

    " Methoden für die allgemeine Flugsuche
    METHODS get_flights_by_route
      IMPORTING
        iv_departure_city TYPE /dmo/city
        iv_arrival_city   TYPE /dmo/city
        iv_flight_date    TYPE /dmo/flight_date
      RETURNING
        VALUE(rt_flights) TYPE tt_flight_details.

    METHODS enhance_flight_data
      CHANGING
        ct_flight_list TYPE tt_flight_details.

    METHODS display_flight_list
      IMPORTING
        if_out         TYPE REF TO if_oo_adt_classrun_out
        it_flight_list TYPE tt_flight_details.

    " Methoden für die Passagier-spezifische Suche
    METHODS get_flights_by_passenger
      IMPORTING
        iv_first_name     TYPE /dmo/first_name
        iv_last_name      TYPE /dmo/last_name
      RETURNING
        VALUE(rt_bookings) TYPE tt_booking_details.

    METHODS display_booking_list
      IMPORTING
        if_out          TYPE REF TO if_oo_adt_classrun_out
        it_booking_list TYPE tt_booking_details.



ENDCLASS.



CLASS zgc_information_fraport_ag IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    "Filtern nach Passagiername

    " Geben Sie hier einen Namen aus der /dmo/customer Tabelle ein (z.B. 'JOHANNES' 'BUCHHOLM')
    DATA lv_first_name TYPE /dmo/first_name VALUE ''.
    DATA lv_last_name  TYPE /dmo/last_name  VALUE ''.

    "Suche nach Flugroute (Namen oben leer)
    DATA lv_departure_city TYPE /dmo/city VALUE 'San Francisco, California'.
    DATA lv_arrival_city   TYPE /dmo/city VALUE 'Singapore'.
    DATA(lv_flight_date)   = CONV /dmo/flight_date( '20260909' ).


    "Logik zur unterscheidung der Suchmodi
    "1. Suche nach Name
    IF lv_first_name IS NOT INITIAL AND lv_last_name IS NOT INITIAL.
      " *** MODUS 1: SUCHE NACH PASSAGIERNAME ***
      TRANSLATE lv_first_name TO UPPER CASE.
      TRANSLATE lv_last_name TO UPPER CASE.
      out->write( |Suche nach gebuchten Flügen für { lv_first_name } { lv_last_name }...| ).
      out->write( '--------------------------------------------------------------------' ).


      DATA(lt_bookings) = get_flights_by_passenger(
        iv_first_name = lv_first_name
        iv_last_name  = lv_last_name
      ).

      IF lt_bookings IS NOT INITIAL.
        display_booking_list( if_out = out it_booking_list = lt_bookings ).
      ELSE.
        out->write( |INFO: Für den Namen '{ lv_first_name } { lv_last_name }' wurden keine Buchungen gefunden.| ).
      ENDIF.

    "2. Suche nach Stadt, Datum
    ELSE.

      TRANSLATE lv_departure_city TO UPPER CASE.
      TRANSLATE lv_arrival_city   TO UPPER CASE.
      out->write( |Suche nach Flügen von '{ lv_departure_city }' nach '{ lv_arrival_city }' am {  lv_flight_date  }...| ).
      out->write( '--------------------------------------------------------------------' ).

      DATA(lt_flights) = get_flights_by_route(
        iv_departure_city = lv_departure_city
        iv_arrival_city   = lv_arrival_city
        iv_flight_date    = lv_flight_date
      ).

      IF lt_flights IS NOT INITIAL.
        enhance_flight_data( CHANGING ct_flight_list = lt_flights ).
        display_flight_list( if_out = out it_flight_list = lt_flights ).

      "Wenn es keine Informationen gibt
      ELSE.
        out->write( |INFO: Für die angegebenen Kriterien wurden keine Flüge gefunden.| ).
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD get_flights_by_route.
    "Liest Flüge anhand der Ortseingaben und des Datums
    SELECT f~carrier_id, f~connection_id, carr~name AS carrier_name, f~flight_date,
           ap_from~city AS departure_city, ap_to~city AS arrival_city,
           c~departure_time, c~arrival_time, f~price, f~currency_code,
           f~seats_max - f~seats_occupied AS seats_available,
           ap_from~airport_id AS departure_airport_id, ap_from~name AS departure_airport_name, ap_from~country AS departure_country,
           ap_to~airport_id AS arrival_airport_id, ap_to~name AS arrival_airport_name, ap_to~country AS arrival_country
      FROM /dmo/flight AS f
      JOIN /dmo/connection AS c       ON  f~carrier_id    = c~carrier_id AND f~connection_id = c~connection_id
      JOIN /dmo/carrier    AS carr    ON f~carrier_id = carr~carrier_id
      JOIN /dmo/airport    AS ap_from ON c~airport_from_id = ap_from~airport_id
      JOIN /dmo/airport    AS ap_to   ON c~airport_to_id = ap_to~airport_id
     WHERE UPPER( ap_from~city ) = @iv_departure_city
       AND UPPER( ap_to~city )   = @iv_arrival_city
       AND f~flight_date = @iv_flight_date
      " Sortiert nach Preis oder Datum
     ORDER BY f~price ASCENDING
     INTO TABLE @rt_flights.
  ENDMETHOD.


  METHOD enhance_flight_data.
    " Erweitert die Flugdaten um die Flugdauer und den Verfügbarkeitstext

    LOOP AT ct_flight_list ASSIGNING FIELD-SYMBOL(<ls_flight>).
      DATA(lv_duration_in_seconds) = COND i( WHEN <ls_flight>-arrival_time > <ls_flight>-departure_time
                                                THEN <ls_flight>-arrival_time - <ls_flight>-departure_time
                                              ELSE ( 24 * 3600 ) - ( <ls_flight>-departure_time - <ls_flight>-arrival_time ) ).
      DATA(lv_hours) = lv_duration_in_seconds / 3600.
      DATA(lv_minutes) = ( lv_duration_in_seconds MOD 3600 ) / 60.
      <ls_flight>-flight_duration_text = |{ lv_hours }h { lv_minutes }m|.

      <ls_flight>-availability_status = COND string( WHEN <ls_flight>-seats_available = 0      THEN 'Ausgebucht'
                                                     WHEN <ls_flight>-seats_available BETWEEN 1 AND 10 THEN 'Nur noch wenige Plätze frei!'
                                                     ELSE 'Verfügbar' ).
    ENDLOOP.
  ENDMETHOD.


  METHOD display_flight_list.
    " Gibt die Liste der gefundenen Flüge in einem kompakten, lesbaren Format aus
    if_out->write( |Gefundene Flüge ({ lines( it_flight_list ) }), sortiert nach Preis:| ).
    if_out->write( | | ).

    LOOP AT it_flight_list INTO DATA(ls_flight).
      DATA(lv_formatted_date) =  ls_flight-flight_date.
      DATA(lv_dep_time) = |{ ls_flight-departure_time TIME = ISO }(5)|. " Schneidet Sekunden ab
      DATA(lv_arr_time) = |{ ls_flight-arrival_time TIME = ISO }(5)|.   " Schneidet Sekunden ab

      if_out->write( |Flug:  { ls_flight-carrier_name } ({ ls_flight-carrier_id }{ ls_flight-connection_id }) am { lv_formatted_date }| ).
      if_out->write( |Route: { ls_flight-departure_airport_name } ({ ls_flight-departure_airport_id }) -> { ls_flight-arrival_airport_name } ({ ls_flight-arrival_airport_id })| ).
      if_out->write( |Zeit:  { lv_dep_time } - { lv_arr_time } (Dauer: { ls_flight-flight_duration_text })| ).
      if_out->write( |Preis: { ls_flight-price } { ls_flight-currency_code } ({ ls_flight-availability_status }: { ls_flight-seats_available } frei)| ).
      if_out->write( '--------------------------------------------------------------------' ).
    ENDLOOP.
  ENDMETHOD.


  METHOD get_flights_by_passenger.
    " Liest gebuchte Flüge anhand des Passagiernamens
    SELECT cust~customer_id, cust~first_name, cust~last_name,
           book~booking_id, carr~name AS carrier_name,
           book~carrier_id, book~connection_id, book~flight_date,
           ap_from~city AS departure_city, ap_to~city AS arrival_city,
           conn~departure_time, conn~arrival_time
      FROM /dmo/customer AS cust
      JOIN /dmo/booking    AS book    ON cust~customer_id = book~customer_id
      JOIN /dmo/carrier    AS carr    ON book~carrier_id = carr~carrier_id
      JOIN /dmo/connection AS conn    ON book~carrier_id    = conn~carrier_id
                                     AND book~connection_id = conn~connection_id
      JOIN /dmo/airport    AS ap_from ON conn~airport_from_id = ap_from~airport_id
      JOIN /dmo/airport    AS ap_to   ON conn~airport_to_id = ap_to~airport_id
     WHERE UPPER( cust~first_name ) = @iv_first_name
       AND UPPER( cust~last_name )  = @iv_last_name
     ORDER BY book~flight_date DESCENDING
      INTO TABLE @rt_bookings.
  ENDMETHOD.


  METHOD display_booking_list.
    " Gibt die Liste der gefundenen Buchungen in einem kompakten, lesbaren Format aus
    DATA(lv_customer_name) = |{ it_booking_list[ 1 ]-first_name } { it_booking_list[ 1 ]-last_name }|.
    if_out->write( |Gefundene Buchungen ({ lines( it_booking_list ) }) für { lv_customer_name }:| ).
    if_out->write( | | ).

    LOOP AT it_booking_list INTO DATA(ls_booking).
      " Status lesbar machen
      DATA(lv_status_text) = COND string( WHEN ls_booking-booking_status = 'B' THEN 'Bestätigt'
                                          WHEN ls_booking-booking_status = 'X' THEN 'Storniert'
                                          ELSE 'Neu' ).

      DATA(lv_formatted_date) = ls_booking-flight_date.
      DATA(lv_dep_time) = |{ ls_booking-departure_time TIME = ISO }(5)|. " Schneidet Sekunden ab
      DATA(lv_arr_time) = |{ ls_booking-arrival_time TIME = ISO }(5)|.   " Schneidet Sekunden ab

      if_out->write( |Buchung: { ls_booking-booking_id } (Status: { lv_status_text })| ).
      if_out->write( |Flug:    { ls_booking-carrier_name } ({ ls_booking-carrier_id }{ ls_booking-connection_id }) am { lv_formatted_date }| ).
      if_out->write( |Route:   { ls_booking-departure_city } -> { ls_booking-arrival_city }| ).
      if_out->write( |Zeit:    { lv_dep_time } - { lv_arr_time }| ).
      if_out->write( '--------------------------------------------------------------------' ).
    ENDLOOP.
  ENDMETHOD.



ENDCLASS.
