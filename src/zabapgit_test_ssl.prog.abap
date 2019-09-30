report zabapgit_test_ssl.

* See https://github.com/larshp/abapGit/

parameters: p_url1 type swc_value default 'https://github.com',
            p_url2 type swc_value default 'https://api.github.com',
            p_id   type ssfapplssl default 'ANONYM'.
* api.github.com is used when pushing code back to github

selection-screen begin of block proxy with frame title text-t01.
* proxy settings, fill if your system is behind a proxy
parameters: p_proxy  type string,
            p_pxport type string,
            p_puser  type string,
            p_ppwd   type string.
selection-screen end of block proxy.

start-of-selection.
  perform run using p_url1.
  write: /, '----', /.
  perform run using p_url2.

form run using iv_url type swc_value.

  data: lv_code          type i,
        lv_url           type string,
        li_client        type ref to if_http_client,
        lt_errors        type table of string,
        lv_error_message type string.

  if iv_url is initial.
    return.
  endif.

  lv_url = iv_url.
  cl_http_client=>create_by_url(
    exporting
      url           = lv_url
      ssl_id        = p_id
      proxy_host    = p_proxy
      proxy_service = p_pxport
    importing
      client        = li_client ).

  if not p_puser is initial.
    li_client->authenticate(
      proxy_authentication = abap_true
      username             = p_puser
      password             = p_ppwd ).
  endif.

  li_client->send( ).
  li_client->receive(
    exceptions
      http_communication_failure = 1
      http_invalid_state         = 2
      http_processing_failed     = 3
      others                     = 4 ).
  if sy-subrc <> 0.
    write: / 'Error Number', sy-subrc, /.
    message id sy-msgid type sy-msgty number sy-msgno with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    li_client->get_last_error(
      importing
        message = lv_error_message ).
    split lv_error_message at cl_abap_char_utilities=>newline into table lt_errors.
    loop at lt_errors into lv_error_message.
      write: / lv_error_message.
    endloop.
    write: / 'Also check transaction SMICM -> Goto -> Trace File -> Display End'.
    return.
  endif.

* if SSL Handshake fails, make sure to also check https://launchpad.support.sap.com/#/notes/510007

  li_client->response->get_status(
    importing
      code = lv_code ).
  if lv_code = 200.
    write: / lv_url, ': ok'.
  else.
    write: / 'Error', lv_code.
  endif.

endform.
