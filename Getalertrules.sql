create or replace PROCEDURE getalertrules(processid in VARCHAR) IS

    msgstatus        VARCHAR2(200);
    cbpname          VARCHAR2(50);
    result           VARCHAR2(100);
    tablehtml        VARCHAR2(2000);
    header           VARCHAR2(20000);
    sql_stm          VARCHAR2(2000);
    totalcnt         NUMBER;
    sentfrom         VARCHAR2(25);
    subject          VARCHAR2(25);
    host             VARCHAR2(25);
    port             NUMBER;
    CURSOR sched IS SELECT a.ad_client_id,a.name, a.ad_alert_id,a.ad_org_id,al.ad_alertprocessor_id,
                           a.startdate,COALESCE(a.enddate, SYSDATE + 1) AS enddate,a.description,
                           a.alertsubject,a.alertmessage,al.frequency,al.frequencytype,ar.selectclause,
                           ar.fromclause,COALESCE(arcp.ad_user_id, - 1) AS user_id,COALESCE(usrl.ad_user_id, - 1) AS role_user_id,
                           COALESCE(bp.c_bpartner_id, - 1) AS bpartner_id,bp.name bpname,
                        (
                            CASE
                                WHEN arcp.ad_user_id != - 1 THEN - 1
                                ELSE COALESCE(arcp.ad_role_id, - 1)
                            END
                        ) AS role_id, COALESCE(usr.email, usrr.email) e_mail,
                          MAX(COALESCE(apr.datenextrun, SYSDATE)) datenextrun
                    FROM ad_alert a
                    INNER JOIN ad_alertprocessor     al ON a.ad_alertprocessor_id = al.ad_alertprocessor_id
                    INNER JOIN ad_alertrule          ar ON ar.ad_alert_id = a.ad_alert_id
                    LEFT JOIN ad_alertprocessresult apr ON apr.ad_alert_id = a.ad_alert_id
                    LEFT JOIN ad_alertrecipient     arcp ON arcp.ad_alert_id = a.ad_alert_id
                    LEFT JOIN ad_user               usr ON usr.ad_user_id = arcp.ad_user_id
                    LEFT JOIN ad_user_roles         usrl ON usrl.ad_role_id = arcp.ad_role_id
                    LEFT JOIN ad_user               usrr ON usrr.ad_user_id = usrl.ad_user_id
                    LEFT JOIN c_bpartner            bp ON bp.c_bpartner_id = ( COALESCE(usr.c_bpartner_id, usrr.c_bpartner_id) )
                    WHERE
                        a.ad_client_id = 1000000 AND a.isactive = 'Y' AND ar.isactive = 'Y'
                        AND al.isactive = 'Y' AND al.frequencytype IN ( 'D', 'H', 'M' )
                        AND a.startdate <= SYSDATE - 1 AND COALESCE(a.enddate, SYSDATE + 1) >= SYSDATE
                        AND COALESCE(usr.email, usrr.email) IS NOT NULL
						AND arcp.ISACTIVE = 'Y'
                    GROUP BY a.ad_client_id,a.name, a.ad_alert_id,a.ad_org_id,
                             al.ad_alertprocessor_id,a.startdate,COALESCE(a.enddate, SYSDATE + 1),
                             a.description,a.alertsubject,a.alertmessage,al.frequency,
                             al.frequencytype,ar.selectclause,ar.fromclause,COALESCE(arcp.ad_user_id, - 1),
                             COALESCE(usrl.ad_user_id, - 1),COALESCE(bp.c_bpartner_id, - 1),
                             bp.name,
                             (
                                 CASE
                                     WHEN arcp.ad_user_id != - 1 THEN - 1
                                     ELSE COALESCE(arcp.ad_role_id, - 1)
                                 END
                             ),COALESCE(usr.email, usrr.email)
                    HAVING MAX(COALESCE(apr.datenextrun, SYSDATE)) <= SYSDATE
                    ORDER BY COALESCE(user_id, role_user_id),a.description;

    TYPE rowscol IS TABLE OF sched%rowtype INDEX BY BINARY_INTEGER;
    p_result rowscol;
BEGIN
    msgstatus := '';
    sentfrom:='<gloriplc3@gmail.com>';
    subject:='G-Plc Performance Alert Message';
    host:='localhost';
    port:=1925;
    OPEN sched;
    FETCH sched
    BULK COLLECT INTO p_result;
    totalcnt:=p_result.count;
    IF(p_result.count > 0) THEN

        sql_stm := p_result(1).selectclause || ' ' || p_result(1).fromclause;
        
        
        
        EXECUTE IMMEDIATE sql_stm INTO result;
        
        tablehtml := CONCAT(tablehtml, '<tr>');
        tablehtml := CONCAT(tablehtml, '<tr><td>' || p_result(1).description || '</td>');
        tablehtml := CONCAT(tablehtml, '<td>' || p_result(1).alertsubject || '</td>');
        tablehtml := CONCAT(tablehtml, '<td>' || result || '</td>');
        tablehtml := CONCAT(tablehtml, '<td>' || p_result(1).alertmessage || '</td></tr>');

        
            INSERT INTO ad_alertprocessresult (ad_alertprocessresult_id, ad_client_id, ad_org_id,
                                               isactive, created, createdby, updated, updatedby,
                                               ad_alert_id, ad_alertprocessor_id, datelastrun,
                                               datenextrun, lastresult) 
            VALUES ((SELECT MAX(ad_alertprocessresult_id) + 1 FROM ad_alertprocessresult),
                    p_result(1).ad_client_id, p_result(1).ad_org_id,
                    'Y',SYSDATE, 1001084, SYSDATE,1001084, p_result(1).ad_alert_id, 
                    p_result(1).ad_alertprocessor_id, SYSDATE,
                    CASE p_result(1).frequencytype
                        WHEN 'M' THEN SYSDATE + ( p_result(1).frequency / 1440 )
                        WHEN 'D' THEN SYSDATE + p_result(1).frequency
                        WHEN 'H' THEN SYSDATE + ( p_result(1).frequency / 24 )
                    END,
                    '[STATUS-NOT-UPDATED]');

    END IF;

    FOR i IN 2..p_result.count LOOP

        IF ( p_result(i).e_mail != p_result(i-1).e_mail) THEN            
            
            cbpname := p_result(i).bpname;

            html_header(header, p_result(i-1).bpname);
            header := header|| tablehtml|| '</table></body></html>';
            send_mail_html('<'|| p_result(i-1).e_mail || '>', sentfrom, 
                    subject, header, host, port, msgstatus);
            tablehtml := '';

            UPDATE ad_alertprocessresult
            SET lastresult = msgstatus || ' | ' || p_result(i-1).e_mail
            WHERE lastresult = '[STATUS-NOT-UPDATED]';

        END IF;

        sql_stm := p_result(i).selectclause || ' ' || p_result(i).fromclause;

        EXECUTE IMMEDIATE sql_stm INTO result;
        
        tablehtml := CONCAT(tablehtml, '<tr>');
        tablehtml := CONCAT(tablehtml, '<tr><td>' || p_result(1).description || '</td>');
        tablehtml := CONCAT(tablehtml, '<td>' || p_result(1).alertsubject || '</td>');
        tablehtml := CONCAT(tablehtml, '<td>' || result || '</td>');
        tablehtml := CONCAT(tablehtml, '<td>' || p_result(i).alertmessage || '</td></tr>');

        IF(p_result(i).ad_alert_id != p_result(i-1).ad_alert_id OR p_result(i).e_mail!=p_result(i-1).e_mail) THEN

            -- Save history --

            INSERT INTO ad_alertprocessresult (
                        ad_alertprocessresult_id, 
                        ad_client_id, ad_org_id, 
                        isactive, created, createdby, updated, updatedby,
                        ad_alert_id, ad_alertprocessor_id, datelastrun, datenextrun, lastresult
                    ) 
            VALUES (
                    (SELECT MAX(ad_alertprocessresult_id) + 1 FROM ad_alertprocessresult),
                    p_result(i).ad_client_id, p_result(i).ad_org_id,
                    'Y',SYSDATE, 1001084, SYSDATE,1001084, 
                    p_result(i).ad_alert_id, p_result(i).ad_alertprocessor_id, SYSDATE,
                    CASE p_result(i).frequencytype
                        WHEN 'M' THEN SYSDATE + ( p_result(i).frequency / 1440 )
                        WHEN 'D' THEN SYSDATE + p_result(i).frequency
                        WHEN 'H' THEN SYSDATE + ( p_result(i).frequency / 24 )
                    END,
                    '[STATUS-NOT-UPDATED]'
                );

        END IF;

    END LOOP;

    
    IF(p_result.count > 0) THEN
        html_header(header, cbpname);
        header := header || tablehtml || '</table></body></html>';
        send_mail_html('<'|| p_result(p_result.count).e_mail || '>',sentfrom , subject, header, host,port, msgstatus);
        -- dbms_output.put_line( p_result(p_result.count).e_mail);
        UPDATE ad_alertprocessresult
        SET lastresult = msgstatus || ' | ' || p_result(totalcnt).e_mail
        WHERE lastresult = '[STATUS-NOT-UPDATED]';

    END IF;
    
    UPDATE ad_sequence
    SET currentnext = (SELECT MAX(ad_alertprocessresult_id) + 1 FROM ad_alertprocessresult)
    WHERE UPPER(name) = 'AD_ALERTPROCESSRESULT';

END getalertrules;
/