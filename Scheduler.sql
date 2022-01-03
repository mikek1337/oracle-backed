create or replace PROCEDURE scheduler IS

    TYPE str IS
        TABLE OF VARCHAR(200);
    TYPE num IS
        TABLE OF NUMBER;
    processorid  num;
    alertid str;
    freq     str;
    freqtype str;
    total    NUMBER;
    jobno number;
    jobnum BINARY_INTEGER;
    oldfreq VARCHAR2(200);
    stm varchar2(4000);
BEGIN
    SELECT DISTINCT(arp.ad_alertprocessor_id),
          (
            CASE
                WHEN arp.frequencytype = 'M' THEN ( arp.frequency / 1440 )
                WHEN arp.frequencytype = 'D' THEN arp.frequency
                WHEN arp.frequencytype = 'H' THEN ( arp.frequency / 24 )
                ELSE 1
            END
            ) AS freq, a.ad_alert_id
    BULK COLLECT INTO processorid,freq,alertid
    FROM ad_alert a
        INNER JOIN ad_alertprocessor arp ON a.ad_alertprocessor_id = arp.ad_alertprocessor_id
    WHERE a.ad_client_id=1000000;
    total := processorid.count;
    FOR i IN 1..total LOOP
    stm:='begin getalertrules('|| processorid(i)||'); end;';
    BEGIN 
        SELECT JOB , INTERVAL INTO jobnum, oldfreq FROM user_jobs where what=stm;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
           dbms_job.submit(
            job=>jobno,
            what=>'begin getalertrules('|| processorid(i)||'); end;',
            interval=>'sysdate + '||freq(i)
        );
        WHEN OTHERS THEN
            NULL;
    END;
    if(oldfreq!='sysdate + '||freq(i)) then
        dbms_output.put_line('new freq: '|| freq(i) ||' old feq: '||oldfreq);
         DBMS_JOB.CHANGE(jobnum,null,null,'sysdate + '||freq(i));
    end if;
    
    END LOOP;

END;