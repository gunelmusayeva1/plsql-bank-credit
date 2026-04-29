<h1>Hi, I'm Gunel! <br/><a href="https://github.com/gunelmusayeva1">SQL & PL/SQL Developer | Data Analyst </a>

<h1>🏦 PL/SQL Bank Credit System</h1>

<p><em>Oracle PL/SQL · Package · MERGE · BULK COLLECT · AUTONOMOUS TRANSACTION · DBMS_SCHEDULER</em></p>

---

<h2>📌 About This Project</h2>

<p>This project models a <b>bank credit eligibility system</b> using Oracle PL/SQL.
It checks whether churned (left the bank) customers can receive a new credit offer.
The system includes packages, procedures, functions, and automated jobs.</p>

---

<h2>🗄️ Tables</h2>

<table>
  <tr>
    <th>Table</th>
    <th>Description</th>
  </tr>
  <tr>
    <td><code>customer_info</code></td>
    <td>Main customer data (CIF, name, gender, age, job)</td>
  </tr>
  <tr>
    <td><code>customer_churn_info</code></td>
    <td>Credit data (credit score, balance, churn status)</td>
  </tr>
  <tr>
    <td><code>updated_list</code></td>
    <td>Updated customer list (used for synchronization)</td>
  </tr>
  <tr>
    <td><code>credit_request</code></td>
    <td>Log of all credit applications</td>
  </tr>
</table>

---

<h2>⚙️ What Was Built</h2>

<h3>1. MERGE — Table Synchronization</h3>
<p>Synchronizes <code>updated_list</code> → <code>customer_churn_info</code>:</p>
<ul>
  <li><b>MATCHED:</b> updates balance and churn columns</li>
  <li><b>NOT MATCHED:</b> inserts a new row</li>
</ul>

<h3>2. Package — <code>check_credit_list</code></h3>

<table>
  <tr>
    <th>Subprogram</th>
    <th>Type</th>
    <th>Description</th>
  </tr>
  <tr>
    <td><code>get_credit_list</code></td>
    <td>FUNCTION</td>
    <td>Returns the credit eligibility status of a customer</td>
  </tr>
  <tr>
    <td><code>check_credit_request</code></td>
    <td>PROCEDURE</td>
    <td>Checks and logs the credit application</td>
  </tr>
  <tr>
    <td><code>credit_offer_amount(id)</code></td>
    <td>FUNCTION</td>
    <td>Returns max credit amount by customer ID</td>
  </tr>
  <tr>
    <td><code>credit_offer_amount(name, surname)</code></td>
    <td>FUNCTION</td>
    <td>Returns max credit amount by name and surname (Overloading)</td>
  </tr>
</table>

<h3>3. Credit Logic</h3>

<p><b>Credit is NOT given</b> if all 3 conditions are true:</p>
<ul>
  <li><code>credit_score &lt; 500</code></li>
  <li><code>churn = 1</code></li>
  <li><code>balance &lt; 2000</code></li>
</ul>

<p><b>Max credit amount — active customer:</b></p>
<ul>
  <li><code>credit_score &lt; 1000</code> → <code>balance × 2</code></li>
  <li><code>credit_score &gt; 1000</code> and <code>balance &gt; 2000</code> → <code>balance × 5</code></li>
</ul>

<p><b>Max credit amount — churned customer (by name/surname):</b></p>
<ul>
  <li><code>credit_score &lt; 1000</code> → <code>balance × 1.5</code></li>
  <li><code>credit_score &gt; 1000</code> and <code>balance &gt; 2000</code> → <code>balance × 2.5</code></li>
</ul>

<h3>4. AUTONOMOUS TRANSACTION</h3>
<p>Every credit application is logged independently — even if the main transaction is rolled back, the log is saved.</p>

<h3>5. DBMS_SCHEDULER</h3>
<p>An automated job runs on the <b>1st of every month</b> to update customer data.</p>

<h3>6. BULK COLLECT</h3>
<p>Used to select the top 10 churned customers with high performance.</p>

<h3>7. SYS_REFCURSOR</h3>
<p>Used to return a result set from a function.</p>

---

<h2>🛠️ Tools & Techniques</h2>

<ul>
  <li><b>Oracle SQL Developer</b></li>
  <li><b>PL/SQL:</b> Package, Procedure, Function, Cursor, Exception Handling</li>
  <li><b>MERGE</b> (UPSERT)</li>
  <li><b>BULK COLLECT</b></li>
  <li><b>AUTONOMOUS TRANSACTION</b></li>
  <li><b>SYS_REFCURSOR</b></li>
  <li><b>DBMS_SCHEDULER</b></li>
  <li>Function Overloading</li>
</ul>

---

<h2> 🤳 Connect with me:</h2>


[<img align="left" alt="JoshMadakor | LinkedIn" width="22px" src="https://cdn.jsdelivr.net/npm/simple-icons@v3/icons/linkedin.svg" />][linkedin]


[linkedin]: https://linkedin.com/in/gunel-musayeva-aa88651aa
[![GitHub](https://img.shields.io/badge/GitHub-black?style=flat&logo=github)](https://github.com/gunelmusayeva1)
