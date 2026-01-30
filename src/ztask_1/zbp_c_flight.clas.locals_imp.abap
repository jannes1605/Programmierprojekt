CLASS lhc_flight DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS checkSeatsAvailability FOR VALIDATE ON SAVE
      IMPORTING keys FOR Flight~checkSeatsAvailability.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Flight RESULT result.
ENDCLASS.

CLASS lhc_flight IMPLEMENTATION.

  METHOD checkSeatsAvailability.
    " Lese die relevanten Flight-Daten
    READ ENTITIES OF ZR_C_FlightTP IN LOCAL MODE
      ENTITY Flight
        FIELDS ( CarrierId ConnectionId FlightDate SeatsMax SeatsOccupied )
        WITH CORRESPONDING #( keys )
      RESULT DATA(flights).

    LOOP AT flights INTO DATA(ls_flight).
      " Prüfung: SeatsOccupied darf nicht größer als SeatsMax sein
      IF ls_flight-SeatsOccupied > ls_flight-SeatsMax.

        " Fehlermeldung anhängen
        APPEND VALUE #(
          %tky = ls_flight-%tky
          %msg = new_message_with_text(
                   severity = if_abap_behv_message=>severity-error
                   text     = |Overbooking! Besetzte Plätze ({ ls_flight-SeatsOccupied }) überschreiten Maximum ({ ls_flight-SeatsMax })|
                 )
          %element-SeatsOccupied = if_abap_behv=>mk-on
        ) TO reported-flight.

        " Markiere den Flight als fehlgeschlagen
        APPEND VALUE #( %tky = ls_flight-%tky ) TO failed-flight.

      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_instance_authorizations.
    " Deine Authorization-Logik (falls benötigt)
  ENDMETHOD.

ENDCLASS.

" =====================================================
" Booking Handler
" =====================================================

CLASS lhc_booking DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS checkFlightCapacity FOR VALIDATE ON SAVE
      IMPORTING keys FOR Booking~checkFlightCapacity.

    METHODS updateFlightSeats FOR DETERMINE ON SAVE
      IMPORTING keys FOR Booking~updateFlightSeats.

    METHODS decreaseFlightSeats FOR DETERMINE ON SAVE
      IMPORTING keys FOR Booking~decreaseFlightSeats.

    METHODS createBooking FOR VALIDATE ON SAVE
      IMPORTING keys FOR Booking~createBooking.
ENDCLASS.

CLASS lhc_booking IMPLEMENTATION.

  METHOD checkFlightCapacity.
    " Lese die neu zu erstellenden Bookings
    READ ENTITIES OF ZR_C_FlightTP IN LOCAL MODE
      ENTITY Booking
        FIELDS ( CarrierId ConnectionId FlightDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(bookings).

    CHECK bookings IS NOT INITIAL.

    " Lese die zugehörigen Flights
    READ ENTITIES OF ZR_C_FlightTP IN LOCAL MODE
      ENTITY Flight
        FIELDS ( CarrierId ConnectionId FlightDate SeatsMax SeatsOccupied )
        WITH VALUE #( FOR wa_booking IN bookings
                      ( CarrierId = wa_booking-CarrierId
                        ConnectionId = wa_booking-ConnectionId
                        FlightDate = wa_booking-FlightDate ) )
      RESULT DATA(flights).

    " Gruppiere und zähle neue Bookings pro Flight
    DATA: BEGIN OF ls_count,
            carrier_id    TYPE /dmo/carrier_id,
            connection_id TYPE /dmo/connection_id,
            flight_date   TYPE /dmo/flight_date,
            count         TYPE i,
          END OF ls_count,
          lt_counts LIKE SORTED TABLE OF ls_count WITH UNIQUE KEY carrier_id connection_id flight_date.

    LOOP AT bookings INTO DATA(ls_booking).
      ls_count-carrier_id = ls_booking-CarrierId.
      ls_count-connection_id = ls_booking-ConnectionId.
      ls_count-flight_date = ls_booking-FlightDate.
      ls_count-count = 1.

      COLLECT ls_count INTO lt_counts.
    ENDLOOP.

    " Prüfe für jeden Flight
    LOOP AT flights INTO DATA(ls_flight).
      " Finde die Anzahl neuer Bookings für diesen Flight
      READ TABLE lt_counts INTO ls_count
        WITH KEY carrier_id = ls_flight-CarrierId
                 connection_id = ls_flight-ConnectionId
                 flight_date = ls_flight-FlightDate.

      IF sy-subrc = 0.
        DATA(future_seats_occupied) = ls_flight-SeatsOccupied + ls_count-count.

        " Prüfe auf Overbooking
        IF future_seats_occupied > ls_flight-SeatsMax.
          " Markiere alle betroffenen Bookings als fehlerhaft
          LOOP AT bookings INTO DATA(ls_booking_err) WHERE CarrierId = ls_flight-CarrierId
                                                       AND ConnectionId = ls_flight-ConnectionId
                                                       AND FlightDate = ls_flight-FlightDate.

            APPEND VALUE #(
              %tky = ls_booking_err-%tky
              %msg = new_message_with_text(
                       severity = if_abap_behv_message=>severity-error
                       text     = |Flight ausgebucht! Verfügbar: { ls_flight-SeatsMax }, Belegt: { ls_flight-SeatsOccupied }|
                     )
              %element-CarrierId = if_abap_behv=>mk-on
              %element-ConnectionId = if_abap_behv=>mk-on
              %element-FlightDate = if_abap_behv=>mk-on
            ) TO reported-booking.

            APPEND VALUE #( %tky = ls_booking_err-%tky ) TO failed-booking.
          ENDLOOP.
        ENDIF.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD updateFlightSeats.
    " Lese die neu erstellten Bookings
    READ ENTITIES OF ZR_C_FlightTP IN LOCAL MODE
      ENTITY Booking
        FIELDS ( CarrierId ConnectionId FlightDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(bookings).

    CHECK bookings IS NOT INITIAL.

    " Gruppiere Bookings nach Flight
    DATA: BEGIN OF ls_count,
            carrier_id    TYPE /dmo/carrier_id,
            connection_id TYPE /dmo/connection_id,
            flight_date   TYPE /dmo/flight_date,
            count         TYPE i,
          END OF ls_count,
          lt_counts LIKE SORTED TABLE OF ls_count WITH UNIQUE KEY carrier_id connection_id flight_date.

    LOOP AT bookings INTO DATA(ls_booking).
      ls_count-carrier_id = ls_booking-CarrierId.
      ls_count-connection_id = ls_booking-ConnectionId.
      ls_count-flight_date = ls_booking-FlightDate.
      ls_count-count = 1.

      COLLECT ls_count INTO lt_counts.
    ENDLOOP.

    " Lese aktuelle Flight-Daten
    READ ENTITIES OF ZR_C_FlightTP IN LOCAL MODE
      ENTITY Flight
        FIELDS ( SeatsOccupied )
        WITH VALUE #( FOR wa_count IN lt_counts
                      ( CarrierId = wa_count-carrier_id
                        ConnectionId = wa_count-connection_id
                        FlightDate = wa_count-flight_date ) )
      RESULT DATA(flights).

    " Bereite Updates vor
    DATA flights_to_update TYPE TABLE FOR UPDATE ZR_C_FlightTP.

    LOOP AT flights INTO DATA(ls_flight).
      READ TABLE lt_counts INTO ls_count
        WITH KEY carrier_id = ls_flight-CarrierId
                 connection_id = ls_flight-ConnectionId
                 flight_date = ls_flight-FlightDate.

      IF sy-subrc = 0.
        APPEND VALUE #(
          %tky = ls_flight-%tky
          SeatsOccupied = ls_flight-SeatsOccupied + ls_count-count
        ) TO flights_to_update.
      ENDIF.
    ENDLOOP.

    " Führe Update aus
    IF flights_to_update IS NOT INITIAL.
      MODIFY ENTITIES OF ZR_C_FlightTP IN LOCAL MODE
        ENTITY Flight
          UPDATE FIELDS ( SeatsOccupied )
          WITH flights_to_update.
    ENDIF.

  ENDMETHOD.

  METHOD decreaseFlightSeats.
    " Lese die gelöschten Bookings
    READ ENTITIES OF ZR_C_FlightTP IN LOCAL MODE
      ENTITY Booking
        FIELDS ( CarrierId ConnectionId FlightDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(bookings).

    CHECK bookings IS NOT INITIAL.

    " Gruppiere Bookings nach Flight
    DATA: BEGIN OF ls_count,
            carrier_id    TYPE /dmo/carrier_id,
            connection_id TYPE /dmo/connection_id,
            flight_date   TYPE /dmo/flight_date,
            count         TYPE i,
          END OF ls_count,
          lt_counts LIKE SORTED TABLE OF ls_count WITH UNIQUE KEY carrier_id connection_id flight_date.

    LOOP AT bookings INTO DATA(ls_booking).
      ls_count-carrier_id = ls_booking-CarrierId.
      ls_count-connection_id = ls_booking-ConnectionId.
      ls_count-flight_date = ls_booking-FlightDate.
      ls_count-count = 1.

      COLLECT ls_count INTO lt_counts.
    ENDLOOP.

    " Lese aktuelle Flight-Daten
    READ ENTITIES OF ZR_C_FlightTP IN LOCAL MODE
      ENTITY Flight
        FIELDS ( SeatsOccupied )
        WITH VALUE #( FOR wa_count IN lt_counts
                      ( CarrierId = wa_count-carrier_id
                        ConnectionId = wa_count-connection_id
                        FlightDate = wa_count-flight_date ) )
      RESULT DATA(flights).

    " Bereite Updates vor
    DATA flights_to_update TYPE TABLE FOR UPDATE ZR_C_FlightTP.

    LOOP AT flights INTO DATA(ls_flight).
      READ TABLE lt_counts INTO ls_count
        WITH KEY carrier_id = ls_flight-CarrierId
                 connection_id = ls_flight-ConnectionId
                 flight_date = ls_flight-FlightDate.

      IF sy-subrc = 0.
        DATA(new_seats) = ls_flight-SeatsOccupied - ls_count-count.
        IF new_seats < 0.
          new_seats = 0.
        ENDIF.

        APPEND VALUE #(
          %tky = ls_flight-%tky
          SeatsOccupied = new_seats
        ) TO flights_to_update.
      ENDIF.
    ENDLOOP.

    " Führe Update aus
    IF flights_to_update IS NOT INITIAL.
      MODIFY ENTITIES OF ZR_C_FlightTP IN LOCAL MODE
        ENTITY Flight
          UPDATE FIELDS ( SeatsOccupied )
          WITH flights_to_update.
    ENDIF.

  ENDMETHOD.

  METHOD createBooking.
    " Deine bestehende Validierung (falls vorhanden)
  ENDMETHOD.

ENDCLASS.
