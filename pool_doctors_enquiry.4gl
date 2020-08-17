SCHEMA pool_doctors

TYPE job_list_type RECORD
    cm_rep_list LIKE customer.cm_rep,
    jh_code_list LIKE job_header.jh_code,
    cm_name_list LIKE customer.cm_name
END RECORD

DEFINE m_job_list_rec job_list_type
DEFINE m_job_list_arr DYNAMIC ARRAY OF job_list_type

DEFINE m_job_detail_rec RECORD LIKE job_detail.*
DEFINE m_job_detail_arr DYNAMIC ARRAY OF RECORD LIKE job_detail.*

DEFINE m_job_note_rec RECORD LIKE job_note.*
DEFINE m_job_note_arr DYNAMIC ARRAY OF RECORD LIKE job_note.*

DEFINE m_job_photo_rec RECORD LIKE job_photo.*
DEFINE m_job_photo_arr DYNAMIC ARRAY OF RECORD LIKE job_photo.*

DEFINE m_job_timesheet_rec RECORD LIKE job_timesheet.*
DEFINE m_job_timesheet_arr DYNAMIC ARRAY OF RECORD LIKE job_timesheet.*

MAIN
    DEFINE l_exit BOOLEAN

    DEFER INTERRUPT
    DEFER QUIT
    OPTIONS FIELD ORDER FORM
    OPTIONS INPUT WRAP

    CALL ui.Interface.loadStyles("pool_doctors_enquiry.4st")
    CLOSE WINDOW screen

    CONNECT TO "pool_doctors"

    OPEN WINDOW w WITH FORM "pool_doctors_enquiry"

    LET l_exit = FALSE

    WHILE NOT l_exit

        DECLARE job_list_curs CURSOR FOR
            SELECT cm_rep, jh_code, cm_name FROM job_header, customer WHERE jh_customer = cm_code ORDER BY cm_rep, jh_code

        CALL m_job_list_arr.clear()
        FOREACH job_list_curs INTO m_job_list_rec.*
            LET m_job_list_arr[m_job_list_arr.getLength() + 1].* = m_job_list_rec.*
        END FOREACH

        DIALOG ATTRIBUTES(UNBUFFERED)
            DISPLAY ARRAY m_job_list_arr TO job_list.*
                BEFORE ROW
                    CALL refresh_job(m_job_list_arr[arr_curr()].jh_code_list)
                    CALL show_photo(m_job_photo_arr[1].jp_code, m_job_photo_arr[1].jp_idx)
            END DISPLAY
            DISPLAY ARRAY m_job_detail_arr TO job_detail.*
            END DISPLAY
            DISPLAY ARRAY m_job_note_arr TO job_note.*
            END DISPLAY
            DISPLAY ARRAY m_job_photo_arr TO job_photo.*
                BEFORE ROW
                    CALL show_photo(m_job_photo_arr[arr_curr()].jp_code, m_job_photo_arr[arr_curr()].jp_idx)
            END DISPLAY
            DISPLAY ARRAY m_job_timesheet_arr TO job_timesheet.*
            END DISPLAY

            ON ACTION refresh
                EXIT DIALOG

            ON ACTION close
                LET l_exit = TRUE
                EXIT DIALOG
        END DIALOG
    END WHILE
END MAIN

FUNCTION refresh_job(l_job_code)
    DEFINE l_job_code LIKE job_header.jh_code
    DEFINE l_job_header RECORD LIKE job_header.*
    DEFINE l_customer RECORD LIKE customer.*

    CALL m_job_detail_arr.clear()
    CALL m_job_note_arr.clear()
    CALL m_job_photo_arr.clear()
    CALL m_job_timesheet_arr.clear()

    -- Job Header
    SELECT job_header.*, cm_name INTO l_job_header.*, l_customer.cm_name FROM job_header, customer
        WHERE jh_customer = cm_code AND jh_code = l_job_code

    DISPLAY BY NAME l_job_header.*
    DISPLAY BY NAME l_customer.cm_name

    -- Job Detail
    DECLARE job_detail_curs CURSOR FOR SELECT * FROM job_detail WHERE jd_code = l_job_code ORDER BY jd_code, jd_line

    FOREACH job_detail_curs INTO m_job_detail_rec.*
        LET m_job_detail_arr[m_job_detail_arr.getLength() + 1].* = m_job_detail_rec.*
    END FOREACH

    -- Job Note
    DECLARE job_note_curs CURSOR FOR SELECT * FROM job_note WHERE jn_code = l_job_code ORDER BY jn_code, jn_idx

    FOREACH job_note_curs INTO m_job_note_rec.*
        LET m_job_note_arr[m_job_note_arr.getLength() + 1].* = m_job_note_rec.*
    END FOREACH

    -- Job Photo
    DECLARE job_photo_curs CURSOR FOR SELECT * FROM job_photo WHERE jp_code = l_job_code ORDER BY jp_code, jp_idx

    LOCATE m_job_photo_rec.jp_photo_data IN FILE "photo.tmp"
    FOREACH job_photo_curs INTO m_job_photo_rec.*
        #   locate m_job_photo_arr[m_job_photo_arr.getLength()+1].jp_photo_data in memory
        LET m_job_photo_arr[m_job_photo_arr.getLength() + 1].* = m_job_photo_rec.*
        # call m_job_photo_arr[m_job_photo_arr.getLength()].jp_photo_data.readFile("photo.tmp")
    END FOREACH
    FREE m_job_photo_rec.jp_photo_data

    -- Job Timesheet
    DECLARE job_timesheet_curs CURSOR FOR SELECT * FROM job_timesheet WHERE jt_code = l_job_code ORDER BY jt_code, jt_idx

    FOREACH job_timesheet_curs INTO m_job_timesheet_rec.*
        LET m_job_timesheet_arr[m_job_timesheet_arr.getLength() + 1].* = m_job_timesheet_rec.*
    END FOREACH
END FUNCTION

FUNCTION show_photo(l_jp_code, l_jp_idx)
    DEFINE l_jp_code LIKE job_photo.jp_code
    DEFINE l_jp_idx LIKE job_photo.jp_idx

    DEFINE b BYTE
    LOCATE b IN FILE "photo.jpg"
    SELECT jp_photo_data INTO b FROM job_photo WHERE jp_code = l_jp_code AND jp_idx = l_jp_idx

    IF status = NOTFOUND THEN
        CLEAR show_photo
    ELSE
        DISPLAY "photo.jpg" TO show_photo
    END IF
    #  free b
END FUNCTION
