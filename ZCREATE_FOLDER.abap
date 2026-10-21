*&---------------------------------------------------------------------*
*& Report ZTEST_CREATE_FOLDER
*&---------------------------------------------------------------------*
* Progarm Name : ZTEST_CREATE_FOLDER
* TCode        : ZFTP_CONN_TEST
* Created by   : Rizki Ahmad
* Created on   : 10.04.2018
*
* Abstract     : Program test to simulate process of creating folder
*                on application server from sap client end node
*
* SAP Functions:
*
* Revision History:
*
*  ChngReq.    Date   Author                Description
* ----------  ------ --------  -----------------------------------------
*-----------------------------------------------------------------------
*
**History:
**----------
**----------------------------------------------------------------------

* WARNING: PROCEED WITH CAUTIONS. THIS PROGRAM IS POWERFUL AND DANGEROUS
* FOR THOSE WHO DOES NOT KNOW WHAT HE/SHE IS DOING!!!
* THIS PROGRAM IS ABLE TO MANIPULATE OR EVEN BREAK SERVER DISK (AL11) !
* PLEASE DO NOT EXECUTE/RUN IF YOU DO NOT NEED TO.

REPORT ztest_create_folder.

TABLES: user_dir.

"ALV section
DATA: t_fieldcat TYPE slis_t_fieldcat_alv WITH HEADER LINE,
      t_layout   TYPE slis_layout_alv.
DATA:       t_sortcat     TYPE slis_t_sortinfo_alv WITH HEADER LINE.
"end of ALV section

DATA: BEGIN OF t_upload OCCURS 0.
DATA: content TYPE string.
DATA: END OF t_upload.

DATA: w_upload LIKE t_upload.

DATA: BEGIN OF t_file OCCURS 0.
DATA: line(255).
DATA: END OF t_file.

"itab
DATA: exec_protocol         LIKE  btcxpm OCCURS 0 WITH HEADER LINE.
DATA: v_cmd                 TYPE sxpgcolist-name VALUE 'MKDIR'.
"variables
DATA: v_addi_param          LIKE sxpgcolist-parameters.
DATA: fullpath              TYPE sxpgcolist-parameters.
DATA: i                     TYPE i.

DATA: t_html TYPE TABLE OF w3html WITH HEADER LINE.
DATA: i_html TYPE TABLE OF w3html WITH HEADER LINE.
DATA: w_html LIKE LINE OF t_html.

DATA: fileline TYPE string.

DATA: sy_subrc TYPE sy-subrc.
DATA: opened TYPE flag.
DATA: file_exists TYPE flag.

DATA: filepath TYPE rlgrap-filename.
DATA: filename TYPE string.
DATA: file_temp TYPE string.

"selection screen
SELECTION-SCREEN: BEGIN OF BLOCK A01 WITH FRAME TITLE text-a01.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(79) text-w01.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(79) text-w02.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(79) text-w03.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN: END OF BLOCK A01.

SELECTION-SCREEN: BEGIN OF BLOCK 001 WITH FRAME TITLE TEXT-001.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: rfile RADIOBUTTON GROUP opt1 DEFAULT 'X' USER-COMMAND abc.
SELECTION-SCREEN: COMMENT 5(11) FOR FIELD rfile.
SELECTION-SCREEN: POSITION 20.
PARAMETERS: rfold RADIOBUTTON GROUP opt1.
SELECTION-SCREEN: COMMENT 25(15) FOR FIELD rfold.
SELECTION-SCREEN: POSITION 40.
PARAMETERS: rdel1 RADIOBUTTON GROUP opt1. "delete by SM69
SELECTION-SCREEN: COMMENT 45(15) FOR FIELD rdel1.
SELECTION-SCREEN: POSITION 60.
PARAMETERS: rdel2 RADIOBUTTON GROUP opt1. "delete by Dataset
SELECTION-SCREEN: COMMENT 65(20) FOR FIELD rdel2.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: rcmd  RADIOBUTTON GROUP opt1. "Terminal/CMD
SELECTION-SCREEN: COMMENT 5(20) FOR FIELD rcmd.
SELECTION-SCREEN: END OF LINE.

PARAMETERS: path   TYPE string LOWER CASE DEFAULT '/usr/sap/interface/'.
PARAMETERS: file   TYPE string LOWER CASE MODIF ID fil DEFAULT 'C:\'.
PARAMETERS: folder TYPE string LOWER CASE MODIF ID fol.

SELECTION-SCREEN SKIP 2.
SELECTION-SCREEN COMMENT 1(50) TEXT-002 MODIF ID fol.
SELECTION-SCREEN: END OF BLOCK 001.

"begin program
INITIALIZATION.
  AUTHORITY-CHECK OBJECT 'S_TCODE'
    ID 'TCD' FIELD 'ZFTP_CONN_TEST'.
  IF sy-subrc NE 0.
    MESSAGE 'You have no authorization for this transaction code' TYPE 'E'.
  ENDIF.

LOAD-OF-PROGRAM.

  CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT'
    EXPORTING
      titel        = 'WARNING'
      textline1    = 'PROCEED WITH CAUTIONS. THIS PROGRAM IS POWERFUL AND DANGEROUS.'
      textline2    = 'PLEASE DO NOT EXECUTE/RUN IF YOU DO NOT NEED TO.'
      start_column = 25
      start_row    = 6.


AT SELECTION-SCREEN OUTPUT.

  LOOP AT SCREEN.
    IF rfile EQ 'X' OR rdel1 EQ 'X' OR rdel2 EQ 'X'.
*      IF screen-name EQ 'FILE'.
      IF screen-group1 EQ 'FIL'.
        IF file IS INITIAL.
          file = 'please_delete_this_file.html'.
        ENDIF.

        screen-active = 1.
      ENDIF.
*      IF screen-name EQ 'FOLDER'.
      IF screen-group1 EQ 'FOL'.
        CLEAR: folder.
        screen-active = 0.
      ENDIF.
    ELSE.
*      IF screen-name EQ 'FILE'.
      IF screen-group1 EQ 'FIL'.
        CLEAR: file.
        screen-active = 0.
      ENDIF.
*      IF screen-name EQ 'FOLDER'.
      IF screen-group1 EQ 'FOL'.
        IF folder IS INITIAL.
          folder = 'please_delete_this_folder'.
        ENDIF.

        screen-active = 1.
      ENDIF.
    ENDIF.

    IF rcmd EQ 'X'.
      IF screen-group1 EQ 'FIL'.
        CLEAR: file.
        screen-active = 0.
      ENDIF.
*      IF screen-name EQ 'FOLDER'.
      IF screen-group1 EQ 'FOL'.
        IF folder IS INITIAL.
          folder = 'please_delete_this_folder'.
        ENDIF.

        screen-active = 0.
      ENDIF.
      IF screen-name EQ 'PATH'.
        screen-input = 0.
      ENDIF.
    ENDIF.
    MODIFY SCREEN.
  ENDLOOP.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR file.
  PERFORM dialog_help.

START-OF-SELECTION.

  IF rcmd IS NOT INITIAL.
    "go to RSBDCOS0
    SUBMIT rsbdcos0 AND RETURN.
  ENDIF.

  i = strlen( path ).

  SUBTRACT 1 FROM i.

  IF path+i(1) NE '/'. "Linux use / .. windows use \
    CONCATENATE path '/' INTO path.
  ENDIF.

  IF rfile EQ 'X'.
*    v_cmd = 'ZTOUCH'.

    REFRESH: t_file, t_upload.

    SPLIT file AT '\' INTO TABLE t_file.
    LOOP AT t_file.
      file_temp = t_file-line.
    ENDLOOP.

    IF file_temp IS INITIAL.
      file_temp = file.
    ENDIF.

    MOVE file_temp TO file.

    CONCATENATE path file INTO fullpath.

    PERFORM get_file.
*    perform create_html changing sy_subrc.
    PERFORM create_file CHANGING sy_subrc.

    IF sy_subrc EQ 0.
      CONCATENATE 'File created at' fullpath INTO exec_protocol-message SEPARATED BY space.
      APPEND exec_protocol.
    ELSE.
      CONCATENATE 'Failed to create file' fullpath INTO exec_protocol-message SEPARATED BY space.
      APPEND exec_protocol.
    ENDIF.

  ELSEIF rdel1 EQ 'X'.
    v_cmd = 'ZDEL'.

    CONCATENATE path file INTO fullpath.
    CALL FUNCTION 'SXPG_COMMAND_EXECUTE'
      EXPORTING
        commandname                   = v_cmd
        additional_parameters         = fullpath
      TABLES
        exec_protocol                 = exec_protocol
      EXCEPTIONS
        no_permission                 = 1
        command_not_found             = 2
        parameters_too_long           = 3
        security_risk                 = 4
        wrong_check_call_interface    = 5
        program_start_error           = 6
        program_termination_error     = 7
        x_error                       = 8
        parameter_expected            = 9
        too_many_parameters           = 10
        illegal_command               = 11
        wrong_asynchronous_parameters = 12
        cant_enq_tbtco_entry          = 13
        jobcount_generation_error     = 14
        OTHERS                        = 15.

    IF sy-subrc EQ 0 AND exec_protocol[] IS INITIAL.
      CONCATENATE 'File' fullpath 'deleted' INTO exec_protocol-message SEPARATED BY space.
*      ENDIF.
      APPEND exec_protocol.
    ENDIF.

  ELSEIF rdel2 EQ 'X'.
    CONCATENATE path file INTO fullpath.
    PERFORM delete_file CHANGING sy_subrc.

    IF sy_subrc EQ 0.
      CONCATENATE 'File ' fullpath 'deleted' INTO exec_protocol-message SEPARATED BY space.
      APPEND exec_protocol.
    ELSE.
      CONCATENATE 'Failed to deleted' fullpath INTO exec_protocol-message SEPARATED BY space.
      APPEND exec_protocol.
    ENDIF.

  ELSEIF rfold EQ 'X'.
    v_cmd = 'ZMKDIR'.

    CONCATENATE path folder INTO fullpath.
    CALL FUNCTION 'SXPG_COMMAND_EXECUTE'
      EXPORTING
        commandname                   = v_cmd
        additional_parameters         = fullpath
      TABLES
        exec_protocol                 = exec_protocol
      EXCEPTIONS
        no_permission                 = 1
        command_not_found             = 2
        parameters_too_long           = 3
        security_risk                 = 4
        wrong_check_call_interface    = 5
        program_start_error           = 6
        program_termination_error     = 7
        x_error                       = 8
        parameter_expected            = 9
        too_many_parameters           = 10
        illegal_command               = 11
        wrong_asynchronous_parameters = 12
        cant_enq_tbtco_entry          = 13
        jobcount_generation_error     = 14
        OTHERS                        = 15.

    IF sy-subrc EQ 0 AND exec_protocol[] IS INITIAL.
*      IF rfile EQ 'X'.
*        concatenate 'File created at' fullpath into exec_protocol-message separated by space.
*      ELSE.
      CONCATENATE 'Folder created at' fullpath INTO exec_protocol-message SEPARATED BY space.
*      ENDIF.
      APPEND exec_protocol.
    ENDIF.
  ENDIF.

  CHECK rcmd IS INITIAL.
  CLEAR: t_layout.
  t_layout-colwidth_optimize = 'X'.
  t_layout-zebra = 'X'.
  t_layout-info_fieldname = 'COLOR'. "to give color to each row

  REFRESH t_fieldcat.

  CLEAR t_fieldcat.
  t_fieldcat-fieldname = 'LENGTH'.
  t_fieldcat-seltext_m = 'LENGTH'.
  APPEND t_fieldcat.

  CLEAR t_fieldcat.
  t_fieldcat-fieldname = 'MESSAGE'.
  t_fieldcat-seltext_m = 'MESSAGE'.
  APPEND t_fieldcat.

  CALL FUNCTION 'REUSE_ALV_LIST_DISPLAY'
    EXPORTING
      i_callback_program = sy-repid
      it_fieldcat        = t_fieldcat[]
      i_save             = 'X'
      is_layout          = t_layout
    TABLES
      t_outtab           = exec_protocol
    EXCEPTIONS
      program_error      = 1
      OTHERS             = 2.


*&---------------------------------------------------------------------*
*&      Form  CREATE_HTML
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM create_html CHANGING subrc TYPE sy-subrc.

  REFRESH: t_html, i_html.
  CLEAR: w_html.

  REFRESH: t_html.
  CLEAR: t_html.
  t_html-line = '<html>'.
  APPEND t_html.
  CLEAR t_html.
  t_html-line = '<head>'.
  APPEND t_html.
  CLEAR t_html.
  t_html-line = '<style>'.
  APPEND t_html.
  CLEAR t_html.
  t_html-line = 'table { border-collapse: collapse; }'.
  APPEND t_html.
  CLEAR t_html.
  t_html-line = '</style>'.
  APPEND t_html.
  CLEAR t_html.
  t_html-line = '</head>'.
  APPEND t_html.

  CLEAR t_html.
  t_html-line = '<table border = "1">'.
  APPEND t_html.

  CLEAR t_html.
  t_html-line = '<tr>'.
  APPEND t_html.

  CLEAR t_html.
  t_html-line = '<td>'.
  APPEND t_html.

  CLEAR t_html.
  t_html-line = 'Hello World'.
  APPEND t_html.

  CLEAR t_html.
  t_html-line = '</td>'.
  APPEND t_html.

  CLEAR t_html.
  t_html-line = '</tr>'.
  APPEND t_html.

  CLEAR t_html.
  t_html-line = '</table>'.
  APPEND t_html.

  CLEAR t_html.
  t_html-line = '</html>'.
  APPEND t_html.

  CLEAR : opened.

  LOOP AT t_html INTO w_html.
    AT FIRST.
      OPEN DATASET fullpath FOR OUTPUT IN TEXT MODE
      ENCODING DEFAULT.
      IF sy-subrc EQ 0.
        opened = 'X'.
      ENDIF.
    ENDAT.

    IF opened EQ 'X'.
      TRANSFER w_html TO fullpath.
    ELSE.
      subrc = sy-subrc.
      EXIT.
    ENDIF.

    AT LAST.
      WAIT UP TO 1 SECONDS.
      CLOSE DATASET fullpath.
    ENDAT.
  ENDLOOP.

  IF sy-subrc NE 0.
    subrc = sy-subrc.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  DELETE_FILE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM delete_file CHANGING subrc TYPE sy-subrc.

  OPEN DATASET fullpath FOR INPUT IN TEXT MODE ENCODING DEFAULT.
  IF sy-subrc = 0.
    file_exists = 'X'.
  ELSE.
    file_exists = ''.
    subrc = sy-subrc.
  ENDIF.
  CLOSE DATASET fullpath.

  IF file_exists IS NOT INITIAL.
    DELETE DATASET fullpath.
    subrc = sy-subrc.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  DIALOG_HELP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM dialog_help .
  CALL FUNCTION 'WS_FILENAME_GET'
    EXPORTING
      def_path         = file
*     mask             = ',*.TXT,*.TXT.'
      mask             = ',*.*,*.*.'
      mode             = 'O'
    IMPORTING
      filename         = filepath
    EXCEPTIONS
      inv_winsys       = 1
      no_batch         = 2
      selection_cancel = 3
      selection_error  = 4
      OTHERS           = 5.
  IF sy-subrc = 0.
    file = filepath.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  GET_FILE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_file .
  CALL FUNCTION 'GUI_UPLOAD'
    EXPORTING
      filename                = file
      filetype                = 'ASC'
      has_field_separator     = 'X'
    TABLES
      data_tab                = t_upload
    EXCEPTIONS
      file_open_error         = 1
      file_read_error         = 2
      no_batch                = 3
      gui_refuse_filetransfer = 4
      invalid_type            = 5
      no_authority            = 6
      unknown_error           = 7
      bad_data_format         = 8
      header_not_allowed      = 9
      separator_not_allowed   = 10
      header_too_long         = 11
      unknown_dp_error        = 12
      access_denied           = 13
      dp_out_of_memory        = 14
      disk_full               = 15
      dp_timeout              = 16
      OTHERS                  = 17.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CREATE_FILE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_SY_SUBRC  text
*----------------------------------------------------------------------*
FORM create_file  CHANGING subrc TYPE sy-subrc.


  CLEAR : opened.

  LOOP AT t_upload INTO w_upload.
    AT FIRST.
      OPEN DATASET fullpath FOR OUTPUT IN TEXT MODE
      ENCODING DEFAULT.
      IF sy-subrc EQ 0.
        opened = 'X'.
      ENDIF.
    ENDAT.

    IF opened EQ 'X'.
      TRANSFER w_upload-content TO fullpath.
    ELSE.
      subrc = sy-subrc.
      EXIT.
    ENDIF.

    AT LAST.
      WAIT UP TO 1 SECONDS.
      CLOSE DATASET fullpath.
    ENDAT.
  ENDLOOP.

  IF sy-subrc NE 0.
    subrc = sy-subrc.
  ENDIF.
ENDFORM.