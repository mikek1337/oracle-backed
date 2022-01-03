create or replace PROCEDURE html_header (
    header OUT VARCHAR2,
    cbpname in varchar2
) IS
    htmlbody VARCHAR2(20000) := '<!DOCTYPE html>
<html>
<head>
<style>
table {
  font-family: arial, sans-serif;
  border-collapse: collapse;
  width: 100%;
}

td, th {
  border: 1px solid #dddddd;
  text-align: left;
  padding: 8px;
}

tr:nth-child(even) {
  background-color: #dddddd;
}
</style>
</head>
<body>
<script>
    function testclick()
    {
        document.getElementById("alert").innerHTML = "Clicked";
    }
    
</script>

<h4> Dear '||cbpname||'</h4>
<p id="alert" >This is you periodic Alert.</>

<table>
 <tr>
    <th>Sn</th>
    <th>Subject</th>
    <th>Measurment</th>
    <th>Message</th>
  </tr>
';
BEGIN
    header := htmlbody;
END html_header;