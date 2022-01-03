create or replace PROCEDURE send_mail_html (
    p_to        IN VARCHAR2,
    p_from      IN VARCHAR2,
    p_subject   IN VARCHAR2,
    p_html_msg  IN VARCHAR2 DEFAULT NULL,
    p_smtp_host IN VARCHAR2,
    p_smtp_port IN NUMBER DEFAULT 110,
    status      out varchar2 
) AS

    l_mail_conn utl_smtp.connection;
    username    VARCHAR2(100) := 'gloriplc3@gmail.com';
    passwords   VARCHAR2(100) := 'cBZW73OLJEti';
    l_boundary  VARCHAR2(5000) := '----=*#abc1234321cba#*=';
    vusername   VARCHAR2(200);
    vpassword   VARCHAR2(200);
    p_text_msg   VARCHAR2(200);
    t1 PLS_INTEGER;
BEGIN
status:='success';
t1:=dbms_utility.get_time;
    vusername := utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(username)));

    vpassword := utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(passwords)));

    l_mail_conn := utl_smtp.open_connection(p_smtp_host, p_smtp_port);
    utl_smtp.helo(l_mail_conn, p_smtp_host);
    utl_smtp.command(l_mail_conn, 'AUTH LOGIN');
    utl_smtp.command(l_mail_conn, vusername);
    utl_smtp.command(l_mail_conn, vpassword);
  --create_html_table(p_html_msg,'ad_station','table{ border:23px solid black;}');
    utl_smtp.mail(l_mail_conn, p_from);
    utl_smtp.rcpt(l_mail_conn, p_to);
    utl_smtp.open_data(l_mail_conn);
  --dbms_output.put_line(p_html_msg);
 
    utl_smtp.write_data(l_mail_conn, 'Date: '
                                     || to_char(sysdate, 'DD-MON-YYYY HH24:MI:SS')
                                     || utl_tcp.crlf);

    utl_smtp.write_data(l_mail_conn, 'To: '
                                     || p_to
                                     || utl_tcp.crlf);
    utl_smtp.write_data(l_mail_conn, 'From: '
                                     || p_from
                                     || utl_tcp.crlf);
    utl_smtp.write_data(l_mail_conn, 'Subject: '
                                     || p_subject
                                     || utl_tcp.crlf);
    utl_smtp.write_data(l_mail_conn, 'Reply-To: '
                                     || p_from
                                     || utl_tcp.crlf);
    utl_smtp.write_data(l_mail_conn, 'MIME-Version: 1.0' || utl_tcp.crlf);
    utl_smtp.write_data(l_mail_conn, 'Content-Type: multipart/alternative; boundary="'
                                     || l_boundary
                                     || '"'
                                     || utl_tcp.crlf
                                     || utl_tcp.crlf);


    utl_smtp.write_data(l_mail_conn, '--'
                                         || l_boundary
                                         || utl_tcp.crlf);
    utl_smtp.write_data(l_mail_conn, 'Content-Type: text/html; charset="iso-8859-1"'
                                         || utl_tcp.crlf
                                         || utl_tcp.crlf);

    utl_smtp.write_data(l_mail_conn, p_html_msg);
    utl_smtp.write_data(l_mail_conn, utl_tcp.crlf || utl_tcp.crlf);
 

    utl_smtp.write_data(l_mail_conn, '--'
                                     || l_boundary
                                     || '--'
                                     || utl_tcp.crlf);

    utl_smtp.close_data(l_mail_conn);
    utl_smtp.quit(l_mail_conn);
    dbms_output.put_line((dbms_utility.get_time - t1)/100 || ' seconds');
    EXCEPTION
    WHEN utl_smtp.transient_error OR utl_smtp.permanent_error THEN
        
        status:='error';
    WHEN OTHERS THEN
     
        dbms_output.put_line('second exception ' || sqlerrm);
        status:='error';
    
END;