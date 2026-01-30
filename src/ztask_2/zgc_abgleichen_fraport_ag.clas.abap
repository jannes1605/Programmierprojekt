CLASS zgc_abgleichen_fraport_ag DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    TYPES:
      BEGIN OF ty_customer_lookup,
        customer_id TYPE /dmo/customer_id,
        full_name   TYPE string,
      END OF ty_customer_lookup.

    TYPES ty_t_customer_lookup TYPE HASHED TABLE OF ty_customer_lookup
                               WITH UNIQUE KEY customer_id.
ENDCLASS.


CLASS zgc_abgleichen_fraport_ag IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    CONSTANTS:
      lc_carrier_id    TYPE /dmo/carrier_id    VALUE 'LH',
      lc_connection_id TYPE /dmo/connection_id VALUE '0400',
      lc_flight_date   TYPE /dmo/flight_date   VALUE '20260912'.

    DATA(lv_flight_date_de) = |{ lc_flight_date+6(2) }.{ lc_flight_date+4(2) }.{ lc_flight_date+0(4) }|.

    DATA(lt_miles_and_more_partners) = VALUE string_table(
      ( `AC` )
      ( `LH` )
      ( `SA` )
      ( `SQ` )
      ( `UA` )
      ( `AZ` )
    ).

    out->write( |Guten Tag, hier ist die Fluggesellschaft { lc_carrier_id }.| ).
    out->write( |Wir beginnen mit dem telefonischen Abgleich für den Flug { lc_carrier_id }-{ lc_connection_id } am { lv_flight_date_de }.| ).
    out->write( '---------------------------------------------------------------------------------------' ).

    DATA(lv_is_partner) = xsdbool( line_exists( lt_miles_and_more_partners[ table_line = lc_carrier_id ] ) ).

    IF lv_is_partner = abap_false.
      out->write( |-> HINWEIS: Die Fluggesellschaft { lc_carrier_id } ist kein Miles & More Partner.| ).
      out->write( '-> Es erfolgt keine Bearbeitung der Passagiere für diesen Flug.' ).
      out->write( '------------------------------------------------------------------' ).
      out->write( 'Der Abgleich ist abgeschlossen.' ).
      RETURN.
    ENDIF.

    out->write( |-> Die Fluggesellschaft { lc_carrier_id } ist ein Miles & More Partner. Die Bearbeitung wird gestartet.| ).

    SELECT *
      FROM /dmo/booking
      WHERE carrier_id    = @lc_carrier_id
        AND connection_id = @lc_connection_id
        AND flight_date   = @lc_flight_date
      INTO TABLE @DATA(lt_bookings).

    IF sy-subrc <> 0 OR lt_bookings IS INITIAL.
      out->write( '-> FEHLER: Für den angegebenen Flug wurden keine Buchungen gefunden.' ).
      out->write( '-> Bitte überprüfen Sie die eingegebenen Werte' ).
      RETURN.
    ENDIF.

    out->write( |-> Wir haben insgesamt { lines( lt_bookings ) } Passagiere auf der Liste.| ).
    out->write( |-> Ich beginne nun mit dem Vorlesen der einzelnen Buchungen...| ).
    out->write( | | ).

    SELECT customer_id, first_name, last_name
      FROM /dmo/customer
      FOR ALL ENTRIES IN @lt_bookings
      WHERE customer_id = @lt_bookings-customer_id
      INTO TABLE @DATA(lt_customers).

    DATA lt_customer_lookup TYPE ty_t_customer_lookup.
    lt_customer_lookup = VALUE #( FOR ls_customer IN lt_customers (
        customer_id = ls_customer-customer_id
        full_name   = |{ ls_customer-first_name } { ls_customer-last_name }|
    ) ).

    LOOP AT lt_bookings INTO DATA(ls_booking).
      DATA lv_customer_name TYPE string.

      READ TABLE lt_customer_lookup INTO DATA(ls_lookup)
        WITH KEY customer_id = ls_booking-customer_id.
      IF sy-subrc = 0.
        lv_customer_name = ls_lookup-full_name.
      ELSE.
        lv_customer_name = |Unbekannter Passagier (ID: { ls_booking-customer_id })|.
      ENDIF.

      DATA(lv_booking_id_str) = |{ ls_booking-booking_id ALPHA = OUT }|.

      out->write( |Nächster Passagier: '{ lv_customer_name }', Buchungsnummer: { lv_booking_id_str }| ).

      DATA(lv_miles) = 1500.

      IF lv_miles = 1500.
        out->write( |-> ZUSATZ: Eine Flasche Wein wird an den Passagier versendet.| ).
      ELSEIF lv_miles = 700.
        out->write( |-> ZUSATZ: Eine Dankeskarte wird an den Passagier versendet.| ).
      ENDIF.
      out->write( | | ).

    ENDLOOP.

    out->write( '------------------------------------------------------------------' ).
    out->write( 'Das waren alle Buchungen für diesen Flug.' ).
    out->write( 'Der Abgleich ist abgeschlossen. Vielen Dank für die Zusammenarbeit!' ).

  ENDMETHOD.
ENDCLASS.

