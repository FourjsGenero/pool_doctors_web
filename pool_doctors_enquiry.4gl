schema pool_doctors

type job_list_type record
    cm_rep_list like customer.cm_rep,
    jh_code_list like job_header.jh_code,
    cm_name_list like customer.cm_name
end record

define m_job_list_rec job_list_type
define m_job_list_arr dynamic array of job_list_type

define m_job_detail_rec record like job_detail.*
define m_job_detail_arr dynamic array of record like job_detail.*

define m_job_note_rec record like job_note.*
define m_job_note_arr dynamic array of record like job_note.*

define m_job_photo_rec record like job_photo.*
define m_job_photo_arr dynamic array of record like job_photo.*

define m_job_timesheet_rec record like job_timesheet.*
define m_job_timesheet_arr dynamic array of record like job_timesheet.*



main
define i integer
define l_exit boolean

    close window screen
    connect to "pool_doctors"
    open window w with form "pool_doctors_enquiry"

    let l_exit = false

    while not l_exit
    
        declare job_list_curs cursor for
        select cm_rep, jh_code, cm_name
        from job_header, customer
        where jh_customer = cm_code
        order by cm_rep, jh_code

        call m_job_list_arr.clear()
        foreach job_list_curs into m_job_list_rec.*
            let m_job_list_arr[m_job_list_arr.getLength()+1].* = m_job_list_rec.*
        end foreach

        dialog attributes(unbuffered)
            display array m_job_list_arr to job_list.*
                before row 
                    call refresh_job(m_job_list_arr[arr_curr()].jh_code_list)
                    call show_photo(m_job_photo_arr[1].jp_code,m_job_photo_arr[1].jp_idx)
            end display
            display array m_job_detail_arr to job_detail.*
            end display
            display array m_job_note_arr to job_note.*
            end display
            display array m_job_photo_arr to job_photo.*
                before row
                    call show_photo(m_job_photo_arr[arr_curr()].jp_code,m_job_photo_arr[arr_curr()].jp_idx)
            end display
            display array m_job_timesheet_arr to job_timesheet.*
            end display

	    on action refresh
                exit dialog
        
            on action close
	        let l_exit = true
                exit dialog
        end dialog
    end while
end main



function refresh_job(l_job_code)
define l_job_code like job_header.jh_code
define l_job_header record like job_header.*
define l_customer record like customer.*
define i integer

    call m_job_detail_arr.clear()
    call m_job_note_arr.clear()
    call m_job_photo_arr.clear()
    call m_job_timesheet_arr.clear()

    -- Job Header
    select job_header.*, cm_name
    into l_job_header.*, l_customer.cm_name
    from job_header, customer
    where jh_customer = cm_code
    and jh_code = l_job_code

    display by name l_job_header.*
    display by name l_customer.cm_name
    
    -- Job Detail
    declare job_detail_curs cursor for
    select *
    from job_detail
    where jd_code = l_job_code
    order by jd_code, jd_line

    foreach job_detail_curs into m_job_detail_rec.*
        let m_job_detail_arr[m_job_detail_arr.getLength()+1].* = m_job_detail_rec.*
    end foreach

    -- Job Note
    declare job_note_curs cursor for
    select *
    from job_note
    where jn_code = l_job_code
    order by jn_code, jn_idx

    foreach job_note_curs into m_job_note_rec.*
        let m_job_note_arr[m_job_note_arr.getLength()+1].* = m_job_note_rec.*
    end foreach

    -- Job Photo
    declare job_photo_curs cursor for
    select *
    from job_photo
    where jp_code = l_job_code
    order by jp_code, jp_idx

    locate m_job_photo_rec.jp_photo_data in file "photo.tmp"
    foreach job_photo_curs into m_job_photo_rec.*
     #   locate m_job_photo_arr[m_job_photo_arr.getLength()+1].jp_photo_data in memory 
        let m_job_photo_arr[m_job_photo_arr.getLength()+1].* = m_job_photo_rec.*
       # call m_job_photo_arr[m_job_photo_arr.getLength()].jp_photo_data.readFile("photo.tmp")
    end foreach
    free m_job_photo_rec.jp_photo_data

    -- Job Timesheet
    declare job_timesheet_curs cursor for
    select *
    from job_timesheet
    where jt_code = l_job_code
    order by jt_code, jt_idx

    foreach job_timesheet_curs into m_job_timesheet_rec.*
        let m_job_timesheet_arr[m_job_timesheet_arr.getLength()+1].* = m_job_timesheet_rec.*
    end foreach
end function

function show_photo(l_jp_code, l_jp_idx)
define l_jp_code like job_photo.jp_code
define l_jp_idx like job_photo.jp_idx

define b byte
    locate b in file "photo.jpg"
    select jp_photo_data
    into b
    from job_photo
    where jp_code = l_jp_code
    and jp_idx = l_jp_idx

    if status = notfound then
        clear show_photo
    else
        display "photo.jpg" to show_photo
    end if
  #  free b
end function

