CLASS zgc_bundesamt_fraport_ag DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_airport_statistic,
        airport_name TYPE /dmo/airport_name,
        flight_count TYPE i,
      END OF ty_airport_statistic.
    TYPES:
      BEGIN OF ty_country_statistic,
        country      TYPE land1,
        flight_count TYPE i,
      END OF ty_country_statistic.
    TYPES:
      BEGIN OF ty_city_statistic,
        city         TYPE /dmo/city,
        flight_count TYPE i,
      END OF ty_city_statistic.
ENDCLASS.

CLASS zgc_bundesamt_fraport_ag IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.

    DATA:
      lv_from_country TYPE land1             VALUE '',
      lv_from_city    TYPE /dmo/city         VALUE '',
      lv_from_airport TYPE /dmo/airport_name VALUE '',

      lv_to_country   TYPE land1             VALUE '',
      lv_to_city      TYPE /dmo/city         VALUE '',
      lv_to_airport   TYPE /dmo/airport_name VALUE '',

      lv_date_from    TYPE /dmo/flight_date  VALUE '20260909',
      lv_date_to      TYPE /dmo/flight_date  VALUE '20261215'.

    DATA lt_dep_by_airport TYPE TABLE OF ty_airport_statistic.
    DATA lt_arr_by_airport TYPE TABLE OF ty_airport_statistic.
    DATA lt_dep_by_country TYPE TABLE OF ty_country_statistic.
    DATA lt_arr_by_country TYPE TABLE OF ty_country_statistic.
    DATA lt_dep_by_city    TYPE TABLE OF ty_city_statistic.
    DATA lt_arr_by_city    TYPE TABLE OF ty_city_statistic.
    DATA lv_output         TYPE string.
    DATA lv_filter_text    TYPE string.

    CONSTANTS lc_initial_date TYPE d VALUE '00000000'.

    DATA lv_date_from_de TYPE string.
    DATA lv_date_to_de   TYPE string.

    IF lv_date_from <> lc_initial_date.
      lv_date_from_de = |{ lv_date_from+6(2) }.{ lv_date_from+4(2) }.{ lv_date_from+0(4) }|.
    ENDIF.

    IF lv_date_to <> lc_initial_date.
      lv_date_to_de = |{ lv_date_to+6(2) }.{ lv_date_to+4(2) }.{ lv_date_to+0(4) }|.
    ENDIF.

    lv_filter_text = 'Flugstatistik für das Bundesamt'.

    IF lv_date_from <> lc_initial_date AND lv_date_to <> lc_initial_date.
      lv_filter_text = |{ lv_filter_text } \| Zeitraum: { lv_date_from_de } - { lv_date_to_de }|.
    ELSEIF lv_date_from <> lc_initial_date.
      lv_filter_text = |{ lv_filter_text } \| Ab: { lv_date_from_de }|.
    ELSEIF lv_date_to <> lc_initial_date.
      lv_filter_text = |{ lv_filter_text } \| Bis: { lv_date_to_de }|.
    ENDIF.

    DATA lv_from_filter TYPE string.
    IF lv_from_country IS NOT INITIAL OR lv_from_city IS NOT INITIAL OR lv_from_airport IS NOT INITIAL.
      lv_from_filter = 'Von:'.
      IF lv_from_country IS NOT INITIAL.
        lv_from_filter = |{ lv_from_filter } Land={ lv_from_country }|.
      ENDIF.
      IF lv_from_city IS NOT INITIAL.
        lv_from_filter = |{ lv_from_filter } Stadt={ lv_from_city }|.
      ENDIF.
      IF lv_from_airport IS NOT INITIAL.
        lv_from_filter = |{ lv_from_filter } Flughafen={ lv_from_airport }|.
      ENDIF.
      lv_filter_text = |{ lv_filter_text } \| { lv_from_filter }|.
    ENDIF.

    DATA lv_to_filter TYPE string.
    IF lv_to_country IS NOT INITIAL OR lv_to_city IS NOT INITIAL OR lv_to_airport IS NOT INITIAL.
      lv_to_filter = 'Nach:'.
      IF lv_to_country IS NOT INITIAL.
        lv_to_filter = |{ lv_to_filter } Land={ lv_to_country }|.
      ENDIF.
      IF lv_to_city IS NOT INITIAL.
        lv_to_filter = |{ lv_to_filter } Stadt={ lv_to_city }|.
      ENDIF.
      IF lv_to_airport IS NOT INITIAL.
        lv_to_filter = |{ lv_to_filter } Flughafen={ lv_to_airport }|.
      ENDIF.
      lv_filter_text = |{ lv_filter_text } \| { lv_to_filter }|.
    ENDIF.

    out->write( lv_filter_text ).
    out->write( '-------------------------------------------------------------------------------------------------' ).
    out->write( cl_abap_char_utilities=>cr_lf ).


    SELECT dep_ap~country, COUNT(*) AS flight_count
      FROM /dmo/flight AS f
      INNER JOIN /dmo/connection AS conn ON f~carrier_id = conn~carrier_id AND f~connection_id = conn~connection_id
      INNER JOIN /dmo/airport AS dep_ap ON conn~airport_from_id = dep_ap~airport_id
      INNER JOIN /dmo/airport AS arr_ap ON conn~airport_to_id = arr_ap~airport_id
      WHERE ( @lv_from_country = '' OR dep_ap~country = @lv_from_country )
        AND ( @lv_from_city = '' OR dep_ap~city = @lv_from_city )
        AND ( @lv_from_airport = '' OR dep_ap~name = @lv_from_airport )
        AND ( @lv_to_country = '' OR arr_ap~country = @lv_to_country )
        AND ( @lv_to_city = '' OR arr_ap~city = @lv_to_city )
        AND ( @lv_to_airport = '' OR arr_ap~name = @lv_to_airport )
        AND ( @lv_date_from = @lc_initial_date OR f~flight_date >= @lv_date_from )
        AND ( @lv_date_to = @lc_initial_date OR f~flight_date <= @lv_date_to )
      GROUP BY dep_ap~country
      ORDER BY flight_count DESCENDING
      INTO TABLE @lt_dep_by_country.

    SELECT arr_ap~country, COUNT(*) AS flight_count
      FROM /dmo/flight AS f
      INNER JOIN /dmo/connection AS conn ON f~carrier_id = conn~carrier_id AND f~connection_id = conn~connection_id
      INNER JOIN /dmo/airport AS arr_ap ON conn~airport_to_id = arr_ap~airport_id
      INNER JOIN /dmo/airport AS dep_ap ON conn~airport_from_id = dep_ap~airport_id
      WHERE ( @lv_from_country = '' OR dep_ap~country = @lv_from_country )
        AND ( @lv_from_city = '' OR dep_ap~city = @lv_from_city )
        AND ( @lv_from_airport = '' OR dep_ap~name = @lv_from_airport )
        AND ( @lv_to_country = '' OR arr_ap~country = @lv_to_country )
        AND ( @lv_to_city = '' OR arr_ap~city = @lv_to_city )
        AND ( @lv_to_airport = '' OR arr_ap~name = @lv_to_airport )
        AND ( @lv_date_from = @lc_initial_date OR f~flight_date >= @lv_date_from )
        AND ( @lv_date_to = @lc_initial_date OR f~flight_date <= @lv_date_to )
      GROUP BY arr_ap~country
      ORDER BY flight_count DESCENDING
      INTO TABLE @lt_arr_by_country.

    SELECT dep_ap~city, COUNT(*) AS flight_count
      FROM /dmo/flight AS f
      INNER JOIN /dmo/connection AS conn ON f~carrier_id = conn~carrier_id AND f~connection_id = conn~connection_id
      INNER JOIN /dmo/airport AS dep_ap ON conn~airport_from_id = dep_ap~airport_id
      INNER JOIN /dmo/airport AS arr_ap ON conn~airport_to_id = arr_ap~airport_id
      WHERE ( @lv_from_country = '' OR dep_ap~country = @lv_from_country )
        AND ( @lv_from_city = '' OR dep_ap~city = @lv_from_city )
        AND ( @lv_from_airport = '' OR dep_ap~name = @lv_from_airport )
        AND ( @lv_to_country = '' OR arr_ap~country = @lv_to_country )
        AND ( @lv_to_city = '' OR arr_ap~city = @lv_to_city )
        AND ( @lv_to_airport = '' OR arr_ap~name = @lv_to_airport )
        AND ( @lv_date_from = @lc_initial_date OR f~flight_date >= @lv_date_from )
        AND ( @lv_date_to = @lc_initial_date OR f~flight_date <= @lv_date_to )
      GROUP BY dep_ap~city
      ORDER BY flight_count DESCENDING
      INTO TABLE @lt_dep_by_city.

    SELECT arr_ap~city, COUNT(*) AS flight_count
      FROM /dmo/flight AS f
      INNER JOIN /dmo/connection AS conn ON f~carrier_id = conn~carrier_id AND f~connection_id = conn~connection_id
      INNER JOIN /dmo/airport AS arr_ap ON conn~airport_to_id = arr_ap~airport_id
      INNER JOIN /dmo/airport AS dep_ap ON conn~airport_from_id = dep_ap~airport_id
      WHERE ( @lv_from_country = '' OR dep_ap~country = @lv_from_country )
        AND ( @lv_from_city = '' OR dep_ap~city = @lv_from_city )
        AND ( @lv_from_airport = '' OR dep_ap~name = @lv_from_airport )
        AND ( @lv_to_country = '' OR arr_ap~country = @lv_to_country )
        AND ( @lv_to_city = '' OR arr_ap~city = @lv_to_city )
        AND ( @lv_to_airport = '' OR arr_ap~name = @lv_to_airport )
        AND ( @lv_date_from = @lc_initial_date OR f~flight_date >= @lv_date_from )
        AND ( @lv_date_to = @lc_initial_date OR f~flight_date <= @lv_date_to )
      GROUP BY arr_ap~city
      ORDER BY flight_count DESCENDING
      INTO TABLE @lt_arr_by_city.

    SELECT dep_ap~name AS airport_name, count(*) AS flight_count
      FROM /dmo/flight AS f
      INNER JOIN /dmo/connection AS conn ON f~carrier_id = conn~carrier_id AND f~connection_id = conn~connection_id
      INNER JOIN /dmo/airport AS dep_ap ON conn~airport_from_id = dep_ap~airport_id
      INNER JOIN /dmo/airport AS arr_ap ON conn~airport_to_id = arr_ap~airport_id
      WHERE ( @lv_from_country = '' OR dep_ap~country = @lv_from_country )
        AND ( @lv_from_city = '' OR dep_ap~city = @lv_from_city )
        AND ( @lv_from_airport = '' OR dep_ap~name = @lv_from_airport )
        AND ( @lv_to_country = '' OR arr_ap~country = @lv_to_country )
        AND ( @lv_to_city = '' OR arr_ap~city = @lv_to_city )
        AND ( @lv_to_airport = '' OR arr_ap~name = @lv_to_airport )
        AND ( @lv_date_from = @lc_initial_date OR f~flight_date >= @lv_date_from )
        AND ( @lv_date_to = @lc_initial_date OR f~flight_date <= @lv_date_to )
      GROUP BY dep_ap~name
      ORDER BY flight_count DESCENDING
      INTO TABLE @lt_dep_by_airport.

    SELECT arr_ap~name AS airport_name, count(*) AS flight_count
      FROM /dmo/flight AS f
      INNER JOIN /dmo/connection AS conn ON f~carrier_id = conn~carrier_id AND f~connection_id = conn~connection_id
      INNER JOIN /dmo/airport AS arr_ap ON conn~airport_to_id = arr_ap~airport_id
      INNER JOIN /dmo/airport AS dep_ap ON conn~airport_from_id = dep_ap~airport_id
      WHERE ( @lv_from_country = '' OR dep_ap~country = @lv_from_country )
        AND ( @lv_from_city = '' OR dep_ap~city = @lv_from_city )
        AND ( @lv_from_airport = '' OR dep_ap~name = @lv_from_airport )
        AND ( @lv_to_country = '' OR arr_ap~country = @lv_to_country )
        AND ( @lv_to_city = '' OR arr_ap~city = @lv_to_city )
        AND ( @lv_to_airport = '' OR arr_ap~name = @lv_to_airport )
        AND ( @lv_date_from = @lc_initial_date OR f~flight_date >= @lv_date_from )
        AND ( @lv_date_to = @lc_initial_date OR f~flight_date <= @lv_date_to )
      GROUP BY arr_ap~name
      ORDER BY flight_count DESCENDING
      INTO TABLE @lt_arr_by_airport.


    out->write( '+-----------------------------------------------+-----------------------------------------------+' ).
    out->write( '|         1. ABFLUEGE PRO LAND                  |         2. LANDUNGEN PRO LAND                 |' ).
    out->write( '+-----------------------------------------------+-----------------------------------------------+' ).
    out->write( '|  Anzahl  |  Land                              |  Anzahl  |  Land                              |' ).
    out->write( '+----------+------------------------------------+----------+------------------------------------+' ).

    DATA lv_max_rows TYPE i.
    lv_max_rows = nmax( val1 = lines( lt_dep_by_country ) val2 = lines( lt_arr_by_country ) ).

    DATA lv_index TYPE i VALUE 1.
    DATA lv_line TYPE string.
    WHILE lv_index <= lv_max_rows.
      DATA lv_left_count TYPE c LENGTH 8.
      DATA lv_left_country TYPE c LENGTH 34.
      DATA lv_right_count TYPE c LENGTH 8.
      DATA lv_right_country TYPE c LENGTH 34.

      READ TABLE lt_dep_by_country INDEX lv_index INTO DATA(ls_dep_country).
      IF sy-subrc = 0.
        lv_left_count = ls_dep_country-flight_count.
        SHIFT lv_left_count RIGHT.
        lv_left_country = ls_dep_country-country.
      ELSE.
        lv_left_count = '        '.
        lv_left_country = '                                  '.
      ENDIF.

      READ TABLE lt_arr_by_country INDEX lv_index INTO DATA(ls_arr_country).
      IF sy-subrc = 0.
        lv_right_count = ls_arr_country-flight_count.
        SHIFT lv_right_count RIGHT.
        lv_right_country = ls_arr_country-country.
      ELSE.
        lv_right_count = '        '.
        lv_right_country = '                                  '.
      ENDIF.

      CONCATENATE '| ' lv_left_count ' | ' lv_left_country ' | ' lv_right_count ' | ' lv_right_country ' |'
        INTO lv_line RESPECTING BLANKS.
      out->write( lv_line ).
      lv_index = lv_index + 1.
    ENDWHILE.

    out->write( '+-----------------------------------------------+-----------------------------------------------+' ).
    out->write( cl_abap_char_utilities=>cr_lf ).


    out->write( '+-----------------------------------------------+-----------------------------------------------+' ).
    out->write( '|         3. ABFLUEGE PRO STADT                 |         4. LANDUNGEN PRO STADT                |' ).
    out->write( '+-----------------------------------------------+-----------------------------------------------+' ).
    out->write( '|  Anzahl  |  Stadt                             |  Anzahl  |  Stadt                             |' ).
    out->write( '+----------+------------------------------------+----------+------------------------------------+' ).

    lv_max_rows = nmax( val1 = lines( lt_dep_by_city ) val2 = lines( lt_arr_by_city ) ).
    lv_index = 1.

    WHILE lv_index <= lv_max_rows.
      DATA lv_left_city TYPE c LENGTH 34.
      DATA lv_right_city TYPE c LENGTH 34.

      READ TABLE lt_dep_by_city INDEX lv_index INTO DATA(ls_dep_city).
      IF sy-subrc = 0.
        lv_left_count = ls_dep_city-flight_count.
        SHIFT lv_left_count RIGHT.
        lv_left_city = ls_dep_city-city.
      ELSE.
        lv_left_count = '        '.
        lv_left_city = '                                  '.
      ENDIF.

      READ TABLE lt_arr_by_city INDEX lv_index INTO DATA(ls_arr_city).
      IF sy-subrc = 0.
        lv_right_count = ls_arr_city-flight_count.
        SHIFT lv_right_count RIGHT.
        lv_right_city = ls_arr_city-city.
      ELSE.
        lv_right_count = '        '.
        lv_right_city = '                                  '.
      ENDIF.

      CONCATENATE '| ' lv_left_count ' | ' lv_left_city ' | ' lv_right_count ' | ' lv_right_city ' |'
        INTO lv_line RESPECTING BLANKS.
      out->write( lv_line ).
      lv_index = lv_index + 1.
    ENDWHILE.

    out->write( '+-----------------------------------------------+-----------------------------------------------+' ).
    out->write( cl_abap_char_utilities=>cr_lf ).


    out->write( '+-----------------------------------------------+-----------------------------------------------+' ).
    out->write( '|         5. ABFLUEGE PRO FLUGHAFEN             |         6. LANDUNGEN PRO FLUGHAFEN            |' ).
    out->write( '+-----------------------------------------------+-----------------------------------------------+' ).
    out->write( '|  Anzahl  |  Flughafen                         |  Anzahl  |  Flughafen                         |' ).
    out->write( '+----------+------------------------------------+----------+------------------------------------+' ).

    lv_max_rows = nmax( val1 = lines( lt_dep_by_airport ) val2 = lines( lt_arr_by_airport ) ).
    lv_index = 1.

    WHILE lv_index <= lv_max_rows.
      DATA lv_left_airport TYPE c LENGTH 34.
      DATA lv_right_airport TYPE c LENGTH 34.

      READ TABLE lt_dep_by_airport INDEX lv_index INTO DATA(ls_dep_airport).
      IF sy-subrc = 0.
        lv_left_count = ls_dep_airport-flight_count.
        SHIFT lv_left_count RIGHT.
        lv_left_airport = ls_dep_airport-airport_name.
      ELSE.
        lv_left_count = '        '.
        lv_left_airport = '                                  '.
      ENDIF.

      READ TABLE lt_arr_by_airport INDEX lv_index INTO DATA(ls_arr_airport).
      IF sy-subrc = 0.
        lv_right_count = ls_arr_airport-flight_count.
        SHIFT lv_right_count RIGHT.
        lv_right_airport = ls_arr_airport-airport_name.
      ELSE.
        lv_right_count = '        '.
        lv_right_airport = '                                  '.
      ENDIF.

      CONCATENATE '| ' lv_left_count ' | ' lv_left_airport ' | ' lv_right_count ' | ' lv_right_airport ' |'
        INTO lv_line RESPECTING BLANKS.
      out->write( lv_line ).
      lv_index = lv_index + 1.
    ENDWHILE.

    out->write( '+-----------------------------------------------+-----------------------------------------------+' ).

  ENDMETHOD.
ENDCLASS.



