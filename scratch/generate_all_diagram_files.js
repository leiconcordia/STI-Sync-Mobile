const fs = require('fs');
const path = require('path');

// Ensure directories exist
const targetDirs = [
  'C:/VSCODE PROJECTS/STI SYNC WEB AND MOBILE/docs/diagrams',
  'C:/VSCODE PROJECTS/STI SYNC WEB AND MOBILE/STI_Sync/docs/diagrams',
  'C:/VSCODE PROJECTS/STI SYNC WEB AND MOBILE/STI Sync Web/docs/diagrams'
];

targetDirs.forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

console.log('Target directories prepared.');

// ==========================================
// 1. PLANTUML GENERATION (.puml)
// ==========================================

const pumlAdmin = `@startuml Admin_Use_Case_Diagram
title STI Sync - SAO / SAS Administrator Use Case Diagram
left to right direction

skinparam defaultFontName Arial
skinparam defaultFontSize 12
skinparam packageStyle rectangle
skinparam shadowing false
skinparam actorStyle awesome

skinparam actor {
    BackgroundColor #FFF2CC
    BorderColor #D6B656
}

skinparam usecase {
    BackgroundColor #DAE8FC
    BorderColor #6C8EBF
    FontColor #001A4D
    FontStyle bold
}

skinparam usecase<<include>> {
    BackgroundColor #F8CECC
    BorderColor #B85450
    FontColor #900C3F
    FontStyle normal
}

skinparam usecase<<extend>> {
    BackgroundColor #FFF2CC
    BorderColor #D6B656
    FontColor #856404
    FontStyle normal
}

actor "SAO / SAS\\nAdministrator" as Admin

rectangle "STI Sync Web - SAO Admin System Boundary" {
    usecase "Log In to Admin Portal" as UC_Login
    usecase "Manage Academic Semesters\\n& Rollover" as UC_Acad
    usecase "Manage Student Registry\\nLifecycle" as UC_Students
    usecase "Govern Student Organizations\\n& Advisers" as UC_Orgs
    usecase "Create Institutional\\nSAS Event" as UC_SAOEvent
    usecase "Review Club Event Proposals" as UC_EventReview
    usecase "Audit Financial Liquidations" as UC_LiqReview
    usecase "Manage Certificate\\nTemplates & Issuance" as UC_Certs
    usecase "Monitor System Audit Logs" as UC_Audit

    ' Included Use Cases
    usecase "Validate Term & Execute\\nTrack Rollover" as UC_Inc_Roll <<include>>
    usecase "Record Immutable\\nAudit Log Entry" as UC_Inc_Audit <<include>>
    usecase "Verify Student ID &\\nSelfie Photo Comparison" as UC_Inc_IDVerify <<include>>
    usecase "Configure Multi-Session\\nTime Windows" as UC_Inc_MultiSession <<include>>
    usecase "Recruit Cross-Org\\nScanner Officers" as UC_Inc_CrossScan <<include>>
    usecase "Calculate Suggested Fee\\n& Budget Pools" as UC_Inc_BudgetCalc <<include>>
    usecase "Generate Cryptographic\\nVerification QR Hash" as UC_Inc_QRHash <<include>>

    ' Extended Use Cases
    usecase "Check Financial Debt\\nClearance Pre-Flight" as UC_Ext_DebtCheck <<extend>>
    usecase "Permanently Purge\\nStudent Archive" as UC_Ext_Purge <<extend>>
    usecase "Request Proposal Revision\\nwith Itemized Notes" as UC_Ext_Revision <<extend>>
    usecase "Enforce Red QR Lock\\nGate Policy" as UC_Ext_QRLockPolicy <<extend>>
    usecase "Batch Promote &\\nRe-Enroll Students" as UC_Ext_Promote <<extend>>
}

' Actor Associations
Admin --> UC_Login
Admin --> UC_Acad
Admin --> UC_Students
Admin --> UC_Orgs
Admin --> UC_SAOEvent
Admin --> UC_EventReview
Admin --> UC_LiqReview
Admin --> UC_Certs
Admin --> UC_Audit

' Include Relationships
UC_Acad ..> UC_Inc_Roll : <<include>>
UC_Acad ..> UC_Inc_Audit : <<include>>
UC_Students ..> UC_Inc_IDVerify : <<include>>
UC_SAOEvent ..> UC_Inc_MultiSession : <<include>>
UC_SAOEvent ..> UC_Inc_CrossScan : <<include>>
UC_SAOEvent ..> UC_Inc_BudgetCalc : <<include>>
UC_Certs ..> UC_Inc_QRHash : <<include>>

' Extend Relationships
UC_Ext_DebtCheck ..> UC_Students : <<extend>>
UC_Ext_Purge ..> UC_Students : <<extend>>
UC_Ext_Promote ..> UC_Students : <<extend>>
UC_Ext_Revision ..> UC_EventReview : <<extend>>
UC_Ext_QRLockPolicy ..> UC_SAOEvent : <<extend>>

@enduml
`;

const pumlOfficer = `@startuml Officer_Use_Case_Diagram
title STI Sync - Student Organization Officer Use Case Diagram
left to right direction

skinparam defaultFontName Arial
skinparam defaultFontSize 12
skinparam packageStyle rectangle
skinparam shadowing false
skinparam actorStyle awesome

skinparam actor {
    BackgroundColor #E1D5E7
    BorderColor #9673A6
}

skinparam usecase {
    BackgroundColor #DAE8FC
    BorderColor #6C8EBF
    FontColor #001A4D
    FontStyle bold
}

skinparam usecase<<include>> {
    BackgroundColor #F8CECC
    BorderColor #B85450
    FontColor #900C3F
    FontStyle normal
}

skinparam usecase<<extend>> {
    BackgroundColor #FFF2CC
    BorderColor #D6B656
    FontColor #856404
    FontStyle normal
}

actor "Organization Officer\\n(Web Portal)" as Officer

rectangle "STI Sync Web - Officer Subsystem Boundary" {
    usecase "Log In to Officer Portal" as UC_OffLogin
    usecase "Create Event Proposal" as UC_Proposal
    usecase "Manage Member Directory" as UC_Members
    usecase "Generate Member Dues\\n& Payables" as UC_Dues
    usecase "Record Cash Payment" as UC_Payment
    usecase "Control QR Ticket\\nGate Status" as UC_QRControl
    usecase "Submit Financial Liquidation" as UC_LiqSubmit
    usecase "Request & Generate\\nCertificates" as UC_CertReq
    usecase "Post Announcements\\n& Live Feeds" as UC_Announce

    ' Included Use Cases
    usecase "Auto-Bind Active\\nHosting Organization" as UC_Inc_AutoOrg <<include>>
    usecase "Assign Scanners from\\nClub Officer Roster" as UC_Inc_ClubScan <<include>>
    usecase "Upload Expense Receipts\\nto Cloudinary" as UC_Inc_ReceiptUpload <<include>>
    usecase "Unlock Student Mobile\\nQR Gate Ticket" as UC_Inc_UnlockQR <<include>>
    usecase "Batch Generate\\nPayable Documents" as UC_Inc_BatchPay <<include>>
    usecase "Filter Verified Present\\nAttendees Only" as UC_Inc_AttendeeList <<include>>

    ' Extended Use Cases
    usecase "Appoint / Promote Member\\nto Officer Position" as UC_Ext_AppointOfficer <<extend>>
    usecase "Manual Gate Ticket\\nOverride Unlock" as UC_Ext_ManualQRUnlock <<extend>>
    usecase "Resubmit Revised\\nLiquidation Report" as UC_Ext_RevisionFix <<extend>>
}

' Actor Associations
Officer --> UC_OffLogin
Officer --> UC_Proposal
Officer --> UC_Members
Officer --> UC_Dues
Officer --> UC_Payment
Officer --> UC_QRControl
Officer --> UC_LiqSubmit
Officer --> UC_CertReq
Officer --> UC_Announce

' Include Relationships
UC_Proposal ..> UC_Inc_AutoOrg : <<include>>
UC_Proposal ..> UC_Inc_ClubScan : <<include>>
UC_Dues ..> UC_Inc_BatchPay : <<include>>
UC_Payment ..> UC_Inc_UnlockQR : <<include>>
UC_LiqSubmit ..> UC_Inc_ReceiptUpload : <<include>>
UC_CertReq ..> UC_Inc_AttendeeList : <<include>>

' Extend Relationships
UC_Ext_AppointOfficer ..> UC_Members : <<extend>>
UC_Ext_ManualQRUnlock ..> UC_QRControl : <<extend>>
UC_Ext_RevisionFix ..> UC_LiqSubmit : <<extend>>

@enduml
`;

const pumlStudent = `@startuml Student_Use_Case_Diagram
title STI Sync - Student Mobile App Use Case Diagram
left to right direction

skinparam defaultFontName Arial
skinparam defaultFontSize 12
skinparam packageStyle rectangle
skinparam shadowing false
skinparam actorStyle awesome

skinparam actor {
    BackgroundColor #D5E8D4
    BorderColor #82B366
}

skinparam usecase {
    BackgroundColor #DAE8FC
    BorderColor #6C8EBF
    FontColor #001A4D
    FontStyle bold
}

skinparam usecase<<include>> {
    BackgroundColor #F8CECC
    BorderColor #B85450
    FontColor #900C3F
    FontStyle normal
}

skinparam usecase<<extend>> {
    BackgroundColor #FFF2CC
    BorderColor #D6B656
    FontColor #856404
    FontStyle normal
}

actor "Student User\\n(Mobile App)" as Student

rectangle "STI Sync Mobile - Student Subsystem Boundary" {
    usecase "Complete 6-Step Registration" as UC_Register
    usecase "Log In to Mobile App" as UC_StudLogin
    usecase "Complete Semester\\nRe-Enrollment" as UC_ReEnroll
    usecase "Browse & Filter Events" as UC_Browse
    usecase "View Event Details & Sessions" as UC_ViewEvent
    usecase "Access Dynamic QR Entry Ticket" as UC_QRTicket
    usecase "View Payables & Fines" as UC_ViewPayables
    usecase "View & Download Certificates" as UC_Certs
    usecase "Manage Student Profile" as UC_Profile

    ' Included Use Cases
    usecase "Upload 2x2 Photo &\\nSchool ID Card" as UC_Inc_UploadID <<include>>
    usecase "Validate Track Active\\nAcademic Term" as UC_Inc_TermValidate <<include>>
    usecase "Generate Signed QR\\nTicket Payload" as UC_Inc_QRPayload <<include>>
    usecase "Itemize Billed Amount,\\nPaid & Balance" as UC_Inc_DebtSummary <<include>>
    usecase "Verify Certificate QR\\nCode Authenticity" as UC_Inc_VerifyCode <<include>>

    ' Extended Use Cases
    usecase "Show Pending Verification\\nStatus Screen" as UC_Ext_PendingScreen <<extend>>
    usecase "Display Red Locked QR\\nTicket Screen" as UC_Ext_QRLockBanner <<extend>>
    usecase "Show Cash Payment\\nRemittance Instructions" as UC_Ext_PayInstruct <<extend>>
    usecase "View Live In/Out\\nAttendance Status" as UC_Ext_AttendanceStatus <<extend>>
}

' Actor Associations
Student --> UC_Register
Student --> UC_StudLogin
Student --> UC_ReEnroll
Student --> UC_Browse
Student --> UC_ViewEvent
Student --> UC_QRTicket
Student --> UC_ViewPayables
Student --> UC_Certs
Student --> UC_Profile

' Include Relationships
UC_Register ..> UC_Inc_UploadID : <<include>>
UC_ReEnroll ..> UC_Inc_TermValidate : <<include>>
UC_QRTicket ..> UC_Inc_QRPayload : <<include>>
UC_ViewPayables ..> UC_Inc_DebtSummary : <<include>>
UC_Certs ..> UC_Inc_VerifyCode : <<include>>

' Extend Relationships
UC_Ext_PendingScreen ..> UC_StudLogin : <<extend>>
UC_Ext_QRLockBanner ..> UC_QRTicket : <<extend>>
UC_Ext_PayInstruct ..> UC_ViewPayables : <<extend>>
UC_Ext_AttendanceStatus ..> UC_QRTicket : <<extend>>

@enduml
`;

const pumlScanner = `@startuml Scanner_Use_Case_Diagram
title STI Sync - Student Scanner Officer Use Case Diagram
left to right direction

skinparam defaultFontName Arial
skinparam defaultFontSize 12
skinparam packageStyle rectangle
skinparam shadowing false
skinparam actorStyle awesome

skinparam actor {
    BackgroundColor #FFE6CC
    BorderColor #D79B00
}

skinparam usecase {
    BackgroundColor #DAE8FC
    BorderColor #6C8EBF
    FontColor #001A4D
    FontStyle bold
}

skinparam usecase<<include>> {
    BackgroundColor #F8CECC
    BorderColor #B85450
    FontColor #900C3F
    FontStyle normal
}

skinparam usecase<<extend>> {
    BackgroundColor #FFF2CC
    BorderColor #D6B656
    FontColor #856404
    FontStyle normal
}

actor "Student Scanner\\nOfficer (Mobile)" as Scanner

rectangle "STI Sync Mobile - Scanner Subsystem Boundary" {
    usecase "Authenticate & Open\\nScanner Mode" as UC_ScanAuth
    usecase "Pre-Cache Event Roster\\nto SQLite (Drift)" as UC_DownloadRoster
    usecase "Scan QR Ticket via Camera" as UC_CameraScan
    usecase "Record Manual / Flagged\\nAttendance Entry" as UC_ManualEntry
    usecase "View Real-Time Gate\\nAttendance Logs" as UC_ViewLogs
    usecase "Synchronize Data\\nwith Cloud Firestore" as UC_SyncCloud

    ' Included Use Cases
    usecase "Validate Scanner Role\\n& Session Permissions" as UC_Inc_CheckRole <<include>>
    usecase "Execute 6-Step Validation\\nPipeline" as UC_Inc_ValPipeline <<include>>
    usecase "Evaluate Grace Period\\n& Late Status" as UC_Inc_EvalGrace <<include>>
    usecase "Save Offline Attendance\\nRecord to SQLite" as UC_Inc_SaveDrift <<include>>
    usecase "Batch Upload Unsynced\\nSQLite Records" as UC_Inc_BatchSync <<include>>

    ' Extended Use Cases
    usecase "Add Walk-in / Unknown\\nAttendee to Session" as UC_Ext_WalkIn <<extend>>
    usecase "Display Visual Result Overlay\\n(Present/Late/Duplicate/Closed)" as UC_Ext_StatusOverlay <<extend>>
    usecase "Inspect & Resolve\\nSync Timestamp Conflicts" as UC_Ext_ResolveConflict <<extend>>
}

' Actor Associations
Scanner --> UC_ScanAuth
Scanner --> UC_DownloadRoster
Scanner --> UC_CameraScan
Scanner --> UC_ManualEntry
Scanner --> UC_ViewLogs
Scanner --> UC_SyncCloud

' Include Relationships
UC_ScanAuth ..> UC_Inc_CheckRole : <<include>>
UC_CameraScan ..> UC_Inc_ValPipeline : <<include>>
UC_CameraScan ..> UC_Inc_EvalGrace : <<include>>
UC_CameraScan ..> UC_Inc_SaveDrift : <<include>>
UC_SyncCloud ..> UC_Inc_BatchSync : <<include>>

' Extend Relationships
UC_Ext_WalkIn ..> UC_ManualEntry : <<extend>>
UC_Ext_StatusOverlay ..> UC_CameraScan : <<extend>>
UC_Ext_ResolveConflict ..> UC_SyncCloud : <<extend>>

@enduml
`;

const pumlUnified = `@startuml Unified_Master_Use_Case_Diagram
title STI Sync - Unified Master Platform Use Case Diagram
left to right direction

skinparam defaultFontName Arial
skinparam defaultFontSize 11
skinparam packageStyle rectangle
skinparam shadowing false
skinparam actorStyle awesome

skinparam usecase {
    BackgroundColor #DAE8FC
    BorderColor #6C8EBF
    FontColor #001A4D
    FontStyle bold
}

actor "SAO / SAS\\nAdministrator\\n(Web)" as Admin #FFF2CC
actor "Student Organization\\nOfficer\\n(Web)" as Officer #E1D5E7
actor "Student User\\n(Mobile)" as Student #D5E8D4
actor "Student Scanner\\nOfficer\\n(Mobile)" as Scanner #FFE6CC

rectangle "STI Sync Integrated Platform Boundary" {
    package "Academic & Identity Governance" {
        usecase "Manage Dual-Track Academic\\nSemesters & Rollover" as UC_Acad
        usecase "Manage Student Registry\\n& ID Verification" as UC_Registry
        usecase "Govern Student Organizations\\n& Charters" as UC_Orgs
    }

    package "Event Management & Gate Access" {
        usecase "Create SAS Institutional Event" as UC_SAOEvent
        usecase "Submit Club Event Proposal" as UC_Proposal
        usecase "Review & Approve Event Proposals" as UC_Approve
        usecase "Browse & Register for Events" as UC_Browse
        usecase "Access Dynamic QR Entry Ticket" as UC_QRTicket
        usecase "Scan QR Entry Ticket at Gate" as UC_ScanGate
        usecase "Record Manual / Walk-in Attendance" as UC_Manual
        usecase "Monitor Real-Time Attendance Logs" as UC_Logs
    }

    package "Financial Payables & Liquidations" {
        usecase "Generate Member Dues & Payables" as UC_Payables
        usecase "Record Cash Payment & Unlock QR Ticket" as UC_Payment
        usecase "View Assigned Payables, Dues & Fines" as UC_ViewPay
        usecase "Submit Financial Liquidation Report" as UC_SubmitLiq
        usecase "Audit & Reconcile Liquidations" as UC_AuditLiq
    }

    package "Certificates & System Governance" {
        usecase "Design & Batch Generate Certificates" as UC_GenCerts
        usecase "Download Verified Digital Certificate" as UC_DownCert
        usecase "Broadcast System / Club Announcements" as UC_Announce
    }
}

' Admin Connections
Admin --> UC_Acad
Admin --> UC_Registry
Admin --> UC_Orgs
Admin --> UC_SAOEvent
Admin --> UC_Approve
Admin --> UC_AuditLiq
Admin --> UC_GenCerts
Admin --> UC_Announce

' Officer Connections
Officer --> UC_Proposal
Officer --> UC_Payables
Officer --> UC_Payment
Officer --> UC_SubmitLiq
Officer --> UC_GenCerts
Officer --> UC_Logs
Officer --> UC_Announce

' Student Connections
Student --> UC_Browse
Student --> UC_QRTicket
Student --> UC_ViewPay
Student --> UC_DownCert

' Scanner Connections
Scanner --> UC_ScanGate
Scanner --> UC_Manual
Scanner --> UC_Logs

@enduml
`;

// Save all PUML files
const pumlFiles = [
  { name: 'admin-use-case-diagram.puml', content: pumlAdmin },
  { name: 'officer-use-case-diagram.puml', content: pumlOfficer },
  { name: 'student-use-case-diagram.puml', content: pumlStudent },
  { name: 'scanner-use-case-diagram.puml', content: pumlScanner },
  { name: 'sti-sync-unified.puml', content: pumlUnified }
];

targetDirs.forEach(dir => {
  pumlFiles.forEach(file => {
    fs.writeFileSync(path.join(dir, file.name), file.content, 'utf8');
  });
});
console.log('Saved all PlantUML (.puml) files.');

// ==========================================
// 2. DRAW.IO XML GENERATION (.drawio)
// ==========================================

function createDrawioXml(diagrams) {
  let xml = '<?xml version="1.0" encoding="UTF-8"?>\n<mxfile host="app.diagrams.net" modified="2026-08-26T02:00:00.000Z" agent="STI Sync Generator" version="24.7.5">\n';
  diagrams.forEach(diag => {
    xml += `  <diagram id="${diag.id}" name="${diag.name}">\n`;
    xml += `    <mxGraphModel dx="1200" dy="800" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1200" pageHeight="900" math="0" shadow="0">\n`;
    xml += `      <root>\n`;
    xml += `        <mxCell id="0" />\n`;
    xml += `        <mxCell id="1" parent="0" />\n`;
    xml += diag.content;
    xml += `      </root>\n`;
    xml += `    </mxGraphModel>\n`;
    xml += `  </diagram>\n`;
  });
  xml += '</mxfile>';
  return xml;
}

// Generate drawio XML content for Admin
function getAdminDrawioContent() {
  return `
        <!-- System Boundary -->
        <mxCell id="sys_admin" value="STI Sync Web - SAO Administrator Subsystem Boundary" style="shape=umlFrame;whiteSpace=wrap;html=1;width=350;height=30;boundedLbl=1;verticalAlign=top;align=left;spacingLeft=10;fillColor=none;strokeColor=#4B6584;strokeWidth=2;" vertex="1" parent="1">
          <mxGeometry x="190" y="40" width="880" height="740" as="geometry" />
        </mxCell>

        <!-- Actor -->
        <mxCell id="act_admin" value="SAO / SAS&lt;br&gt;&lt;b&gt;Administrator&lt;/b&gt;" style="shape=umlActor;verticalLabelPosition=bottom;verticalAlign=top;html=1;outlineConnect=0;fillColor=#FFF2CC;strokeColor=#D6B656;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="60" y="320" width="50" height="90" as="geometry" />
        </mxCell>

        <!-- Base Use Cases (Blue Ovals) -->
        <mxCell id="uc_adm_1" value="Log In to Admin Portal" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="80" width="200" height="55" as="geometry" />
        </mxCell>
        <mxCell id="uc_adm_2" value="Manage Academic Semesters&lt;br&gt;&amp;amp; Rollover Engine" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="155" width="200" height="55" as="geometry" />
        </mxCell>
        <mxCell id="uc_adm_3" value="Manage Student Registry&lt;br&gt;&amp;amp; Lifecycle" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="230" width="200" height="55" as="geometry" />
        </mxCell>
        <mxCell id="uc_adm_4" value="Govern Student Organizations&lt;br&gt;&amp;amp; Advisers" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="305" width="200" height="55" as="geometry" />
        </mxCell>
        <mxCell id="uc_adm_5" value="Create Institutional&lt;br&gt;SAS Event" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="380" width="200" height="55" as="geometry" />
        </mxCell>
        <mxCell id="uc_adm_6" value="Review Club Event Proposals" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="455" width="200" height="55" as="geometry" />
        </mxCell>
        <mxCell id="uc_adm_7" value="Audit Financial Liquidations" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="530" width="200" height="55" as="geometry" />
        </mxCell>
        <mxCell id="uc_adm_8" value="Manage Certificate&lt;br&gt;Templates &amp;amp; Issuance" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="605" width="200" height="55" as="geometry" />
        </mxCell>
        <mxCell id="uc_adm_9" value="Monitor System Audit Logs" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="680" width="200" height="55" as="geometry" />
        </mxCell>

        <!-- Included Use Cases (Pink Ovals) -->
        <mxCell id="uc_inc_adm_1" value="Validate Term &amp;amp; Execute&lt;br&gt;Track Rollover" style="ellipse;whiteSpace=wrap;html=1;fillColor=#F8CECC;strokeColor=#B85450;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="610" y="110" width="190" height="50" as="geometry" />
        </mxCell>
        <mxCell id="uc_inc_adm_2" value="Record Immutable&lt;br&gt;Audit Log Entry" style="ellipse;whiteSpace=wrap;html=1;fillColor=#F8CECC;strokeColor=#B85450;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="610" y="170" width="190" height="50" as="geometry" />
        </mxCell>
        <mxCell id="uc_inc_adm_3" value="Verify Student ID &amp;amp;&lt;br&gt;Selfie Photos" style="ellipse;whiteSpace=wrap;html=1;fillColor=#F8CECC;strokeColor=#B85450;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="610" y="230" width="190" height="50" as="geometry" />
        </mxCell>
        <mxCell id="uc_inc_adm_4" value="Configure Multi-Session&lt;br&gt;Time Windows" style="ellipse;whiteSpace=wrap;html=1;fillColor=#F8CECC;strokeColor=#B85450;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="610" y="320" width="190" height="50" as="geometry" />
        </mxCell>
        <mxCell id="uc_inc_adm_5" value="Recruit Cross-Org&lt;br&gt;Scanner Officers" style="ellipse;whiteSpace=wrap;html=1;fillColor=#F8CECC;strokeColor=#B85450;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="610" y="380" width="190" height="50" as="geometry" />
        </mxCell>
        <mxCell id="uc_inc_adm_6" value="Calculate Suggested Fee&lt;br&gt;&amp;amp; Budget Pools" style="ellipse;whiteSpace=wrap;html=1;fillColor=#F8CECC;strokeColor=#B85450;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="610" y="440" width="190" height="50" as="geometry" />
        </mxCell>
        <mxCell id="uc_inc_adm_7" value="Generate Verification&lt;br&gt;QR Hash" style="ellipse;whiteSpace=wrap;html=1;fillColor=#F8CECC;strokeColor=#B85450;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="610" y="605" width="190" height="50" as="geometry" />
        </mxCell>

        <!-- Extended Use Cases (Yellow Ovals) -->
        <mxCell id="uc_ext_adm_1" value="Check Financial Debt&lt;br&gt;Clearance Pre-Flight" style="ellipse;whiteSpace=wrap;html=1;fillColor=#FFF2CC;strokeColor=#D6B656;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="840" y="200" width="190" height="50" as="geometry" />
        </mxCell>
        <mxCell id="uc_ext_adm_2" value="Permanently Purge&lt;br&gt;Student Archive" style="ellipse;whiteSpace=wrap;html=1;fillColor=#FFF2CC;strokeColor=#D6B656;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="840" y="260" width="190" height="50" as="geometry" />
        </mxCell>
        <mxCell id="uc_ext_adm_3" value="Enforce Red QR Lock&lt;br&gt;Gate Policy" style="ellipse;whiteSpace=wrap;html=1;fillColor=#FFF2CC;strokeColor=#D6B656;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="840" y="380" width="190" height="50" as="geometry" />
        </mxCell>
        <mxCell id="uc_ext_adm_4" value="Request Proposal Revision&lt;br&gt;with Feedback Notes" style="ellipse;whiteSpace=wrap;html=1;fillColor=#FFF2CC;strokeColor=#D6B656;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="610" y="500" width="190" height="50" as="geometry" />
        </mxCell>

        <!-- Associations (Solid Lines) -->
        <mxCell id="edge_adm_1" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_admin" target="uc_adm_1"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="edge_adm_2" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_admin" target="uc_adm_2"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="edge_adm_3" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_admin" target="uc_adm_3"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="edge_adm_4" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_admin" target="uc_adm_4"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="edge_adm_5" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_admin" target="uc_adm_5"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="edge_adm_6" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_admin" target="uc_adm_6"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="edge_adm_7" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_admin" target="uc_adm_7"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="edge_adm_8" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_admin" target="uc_adm_8"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="edge_adm_9" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_admin" target="uc_adm_9"><mxGeometry relative="1" as="geometry" /></mxCell>

        <!-- Include Relationships (Dashed with open arrow) -->
        <mxCell id="inc_adm_1" value="&amp;lt;&amp;lt;include&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#900C3F;fontColor=#900C3F;" edge="1" parent="1" source="uc_adm_2" target="uc_inc_adm_1"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="inc_adm_2" value="&amp;lt;&amp;lt;include&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#900C3F;fontColor=#900C3F;" edge="1" parent="1" source="uc_adm_2" target="uc_inc_adm_2"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="inc_adm_3" value="&amp;lt;&amp;lt;include&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#900C3F;fontColor=#900C3F;" edge="1" parent="1" source="uc_adm_3" target="uc_inc_adm_3"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="inc_adm_4" value="&amp;lt;&amp;lt;include&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#900C3F;fontColor=#900C3F;" edge="1" parent="1" source="uc_adm_5" target="uc_inc_adm_4"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="inc_adm_5" value="&amp;lt;&amp;lt;include&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#900C3F;fontColor=#900C3F;" edge="1" parent="1" source="uc_adm_5" target="uc_inc_adm_5"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="inc_adm_6" value="&amp;lt;&amp;lt;include&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#900C3F;fontColor=#900C3F;" edge="1" parent="1" source="uc_adm_5" target="uc_inc_adm_6"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="inc_adm_7" value="&amp;lt;&amp;lt;include&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#900C3F;fontColor=#900C3F;" edge="1" parent="1" source="uc_adm_8" target="uc_inc_adm_7"><mxGeometry relative="1" as="geometry" /></mxCell>

        <!-- Extend Relationships (Dashed with open arrow pointing to base) -->
        <mxCell id="ext_adm_1" value="&amp;lt;&amp;lt;extend&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#856404;fontColor=#856404;" edge="1" parent="1" source="uc_ext_adm_1" target="uc_adm_3"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="ext_adm_2" value="&amp;lt;&amp;lt;extend&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#856404;fontColor=#856404;" edge="1" parent="1" source="uc_ext_adm_2" target="uc_adm_3"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="ext_adm_3" value="&amp;lt;&amp;lt;extend&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#856404;fontColor=#856404;" edge="1" parent="1" source="uc_ext_adm_3" target="uc_adm_5"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="ext_adm_4" value="&amp;lt;&amp;lt;extend&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#856404;fontColor=#856404;" edge="1" parent="1" source="uc_ext_adm_4" target="uc_adm_6"><mxGeometry relative="1" as="geometry" /></mxCell>
  `;
}

// Generate drawio XML content for Officer
function getOfficerDrawioContent() {
  return `
        <!-- System Boundary -->
        <mxCell id="sys_off" value="STI Sync Web - Student Organization Officer Subsystem Boundary" style="shape=umlFrame;whiteSpace=wrap;html=1;width=380;height=30;boundedLbl=1;verticalAlign=top;align=left;spacingLeft=10;fillColor=none;strokeColor=#83358E;strokeWidth=2;" vertex="1" parent="1">
          <mxGeometry x="190" y="40" width="880" height="740" as="geometry" />
        </mxCell>

        <!-- Actor -->
        <mxCell id="act_off" value="Organization&lt;br&gt;&lt;b&gt;Officer (Web)&lt;/b&gt;" style="shape=umlActor;verticalLabelPosition=bottom;verticalAlign=top;html=1;outlineConnect=0;fillColor=#E1D5E7;strokeColor=#9673A6;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="60" y="320" width="50" height="90" as="geometry" />
        </mxCell>

        <!-- Base Use Cases -->
        <mxCell id="uc_off_1" value="Log In to Officer Portal" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="80" width="200" height="55" as="geometry" />
        </mxCell>
        <mxCell id="uc_off_2" value="Create Event Proposal" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="155" width="200" height="55" as="geometry" />
        </mxCell>
        <mxCell id="uc_off_3" value="Manage Member Directory" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="230" width="200" height="55" as="geometry" />
        </mxCell>
        <mxCell id="uc_off_4" value="Generate Member Dues&lt;br&gt;&amp;amp; Payables" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="305" width="200" height="55" as="geometry" />
        </mxCell>
        <mxCell id="uc_off_5" value="Record Cash Payment" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="380" width="200" height="55" as="geometry" />
        </mxCell>
        <mxCell id="uc_off_6" value="Control QR Ticket&lt;br&gt;Gate Status" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="455" width="200" height="55" as="geometry" />
        </mxCell>
        <mxCell id="uc_off_7" value="Submit Financial Liquidation" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="530" width="200" height="55" as="geometry" />
        </mxCell>
        <mxCell id="uc_off_8" value="Request &amp;amp; Generate&lt;br&gt;Certificates" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="605" width="200" height="55" as="geometry" />
        </mxCell>
        <mxCell id="uc_off_9" value="Post Announcements" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="680" width="200" height="55" as="geometry" />
        </mxCell>

        <!-- Included Use Cases -->
        <mxCell id="uc_inc_off_1" value="Auto-Bind Active&lt;br&gt;Hosting Organization" style="ellipse;whiteSpace=wrap;html=1;fillColor=#F8CECC;strokeColor=#B85450;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="610" y="130" width="190" height="50" as="geometry" />
        </mxCell>
        <mxCell id="uc_inc_off_2" value="Assign Scanners from&lt;br&gt;Club Officer Roster" style="ellipse;whiteSpace=wrap;html=1;fillColor=#F8CECC;strokeColor=#B85450;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="610" y="190" width="190" height="50" as="geometry" />
        </mxCell>
        <mxCell id="uc_inc_off_3" value="Batch Generate&lt;br&gt;Payable Documents" style="ellipse;whiteSpace=wrap;html=1;fillColor=#F8CECC;strokeColor=#B85450;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="610" y="305" width="190" height="50" as="geometry" />
        </mxCell>
        <mxCell id="uc_inc_off_4" value="Unlock Student Mobile&lt;br&gt;QR Ticket in Real-Time" style="ellipse;whiteSpace=wrap;html=1;fillColor=#F8CECC;strokeColor=#B85450;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="610" y="380" width="190" height="50" as="geometry" />
        </mxCell>
        <mxCell id="uc_inc_off_5" value="Upload Receipts to&lt;br&gt;Cloudinary Storage" style="ellipse;whiteSpace=wrap;html=1;fillColor=#F8CECC;strokeColor=#B85450;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="610" y="530" width="190" height="50" as="geometry" />
        </mxCell>
        <mxCell id="uc_inc_off_6" value="Filter Verified Present&lt;br&gt;Attendees Only" style="ellipse;whiteSpace=wrap;html=1;fillColor=#F8CECC;strokeColor=#B85450;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="610" y="605" width="190" height="50" as="geometry" />
        </mxCell>

        <!-- Extended Use Cases -->
        <mxCell id="uc_ext_off_1" value="Appoint / Promote Member&lt;br&gt;to Officer Position" style="ellipse;whiteSpace=wrap;html=1;fillColor=#FFF2CC;strokeColor=#D6B656;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="610" y="245" width="190" height="50" as="geometry" />
        </mxCell>
        <mxCell id="uc_ext_off_2" value="Manual Gate Ticket&lt;br&gt;Override Unlock" style="ellipse;whiteSpace=wrap;html=1;fillColor=#FFF2CC;strokeColor=#D6B656;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="610" y="455" width="190" height="50" as="geometry" />
        </mxCell>
        <mxCell id="uc_ext_off_3" value="Resubmit Revised&lt;br&gt;Liquidation Report" style="ellipse;whiteSpace=wrap;html=1;fillColor=#FFF2CC;strokeColor=#D6B656;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="840" y="530" width="190" height="50" as="geometry" />
        </mxCell>

        <!-- Associations -->
        <mxCell id="edge_off_1" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_off" target="uc_off_1"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="edge_off_2" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_off" target="uc_off_2"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="edge_off_3" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_off" target="uc_off_3"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="edge_off_4" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_off" target="uc_off_4"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="edge_off_5" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_off" target="uc_off_5"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="edge_off_6" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_off" target="uc_off_6"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="edge_off_7" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_off" target="uc_off_7"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="edge_off_8" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_off" target="uc_off_8"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="edge_off_9" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_off" target="uc_off_9"><mxGeometry relative="1" as="geometry" /></mxCell>

        <!-- Include Relationships -->
        <mxCell id="inc_off_1" value="&amp;lt;&amp;lt;include&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#900C3F;fontColor=#900C3F;" edge="1" parent="1" source="uc_off_2" target="uc_inc_off_1"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="inc_off_2" value="&amp;lt;&amp;lt;include&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#900C3F;fontColor=#900C3F;" edge="1" parent="1" source="uc_off_2" target="uc_inc_off_2"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="inc_off_3" value="&amp;lt;&amp;lt;include&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#900C3F;fontColor=#900C3F;" edge="1" parent="1" source="uc_off_4" target="uc_inc_off_3"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="inc_off_4" value="&amp;lt;&amp;lt;include&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#900C3F;fontColor=#900C3F;" edge="1" parent="1" source="uc_off_5" target="uc_inc_off_4"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="inc_off_5" value="&amp;lt;&amp;lt;include&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#900C3F;fontColor=#900C3F;" edge="1" parent="1" source="uc_off_7" target="uc_inc_off_5"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="inc_off_6" value="&amp;lt;&amp;lt;include&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#900C3F;fontColor=#900C3F;" edge="1" parent="1" source="uc_off_8" target="uc_inc_off_6"><mxGeometry relative="1" as="geometry" /></mxCell>

        <!-- Extend Relationships -->
        <mxCell id="ext_off_1" value="&amp;lt;&amp;lt;extend&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#856404;fontColor=#856404;" edge="1" parent="1" source="uc_ext_off_1" target="uc_off_3"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="ext_off_2" value="&amp;lt;&amp;lt;extend&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#856404;fontColor=#856404;" edge="1" parent="1" source="uc_ext_off_2" target="uc_off_6"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="ext_off_3" value="&amp;lt;&amp;lt;extend&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#856404;fontColor=#856404;" edge="1" parent="1" source="uc_ext_off_3" target="uc_off_7"><mxGeometry relative="1" as="geometry" /></mxCell>
  `;
}

// Generate drawio XML content for Student
function getStudentDrawioContent() {
  return `
        <!-- System Boundary -->
        <mxCell id="sys_stu" value="STI Sync Mobile - Student User Subsystem Boundary" style="shape=umlFrame;whiteSpace=wrap;html=1;width=350;height=30;boundedLbl=1;verticalAlign=top;align=left;spacingLeft=10;fillColor=none;strokeColor=#27AE60;strokeWidth=2;" vertex="1" parent="1">
          <mxGeometry x="190" y="40" width="880" height="740" as="geometry" />
        </mxCell>

        <!-- Actor -->
        <mxCell id="act_stu" value="Student User&lt;br&gt;&lt;b&gt;(Mobile App)&lt;/b&gt;" style="shape=umlActor;verticalLabelPosition=bottom;verticalAlign=top;html=1;outlineConnect=0;fillColor=#D5E8D4;strokeColor=#82B366;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="60" y="320" width="50" height="90" as="geometry" />
        </mxCell>

        <!-- Base Use Cases -->
        <mxCell id="uc_stu_1" value="Complete 6-Step Registration" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="80" width="200" height="55" as="geometry" />
        </mxCell>
        <mxCell id="uc_stu_2" value="Log In to Mobile App" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="155" width="200" height="55" as="geometry" />
        </mxCell>
        <mxCell id="uc_stu_3" value="Complete Semester&lt;br&gt;Re-Enrollment" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="230" width="200" height="55" as="geometry" />
        </mxCell>
        <mxCell id="uc_stu_4" value="Browse &amp;amp; Filter Events" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="305" width="200" height="55" as="geometry" />
        </mxCell>
        <mxCell id="uc_stu_5" value="View Event Details &amp;amp; Sessions" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="380" width="200" height="55" as="geometry" />
        </mxCell>
        <mxCell id="uc_stu_6" value="Access Dynamic QR&lt;br&gt;Entry Ticket" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="455" width="200" height="55" as="geometry" />
        </mxCell>
        <mxCell id="uc_stu_7" value="View Payables &amp;amp; Fines" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="530" width="200" height="55" as="geometry" />
        </mxCell>
        <mxCell id="uc_stu_8" value="View &amp;amp; Download&lt;br&gt;Certificates" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="605" width="200" height="55" as="geometry" />
        </mxCell>
        <mxCell id="uc_stu_9" value="Manage Student Profile" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="680" width="200" height="55" as="geometry" />
        </mxCell>

        <!-- Included Use Cases -->
        <mxCell id="uc_inc_stu_1" value="Upload 2x2 Photo &amp;amp;&lt;br&gt;School ID Card" style="ellipse;whiteSpace=wrap;html=1;fillColor=#F8CECC;strokeColor=#B85450;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="610" y="80" width="190" height="50" as="geometry" />
        </mxCell>
        <mxCell id="uc_inc_stu_2" value="Validate Track Active&lt;br&gt;Academic Term" style="ellipse;whiteSpace=wrap;html=1;fillColor=#F8CECC;strokeColor=#B85450;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="610" y="230" width="190" height="50" as="geometry" />
        </mxCell>
        <mxCell id="uc_inc_stu_3" value="Generate Signed QR&lt;br&gt;Ticket Payload" style="ellipse;whiteSpace=wrap;html=1;fillColor=#F8CECC;strokeColor=#B85450;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="610" y="440" width="190" height="50" as="geometry" />
        </mxCell>
        <mxCell id="uc_inc_stu_4" value="Itemize Billed Amount,&lt;br&gt;Paid &amp;amp; Balance" style="ellipse;whiteSpace=wrap;html=1;fillColor=#F8CECC;strokeColor=#B85450;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="610" y="530" width="190" height="50" as="geometry" />
        </mxCell>
        <mxCell id="uc_inc_stu_5" value="Verify Certificate QR&lt;br&gt;Code Authenticity" style="ellipse;whiteSpace=wrap;html=1;fillColor=#F8CECC;strokeColor=#B85450;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="610" y="605" width="190" height="50" as="geometry" />
        </mxCell>

        <!-- Extended Use Cases -->
        <mxCell id="uc_ext_stu_1" value="Show Pending Verification&lt;br&gt;Status Screen" style="ellipse;whiteSpace=wrap;html=1;fillColor=#FFF2CC;strokeColor=#D6B656;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="610" y="155" width="190" height="50" as="geometry" />
        </mxCell>
        <mxCell id="uc_ext_stu_2" value="Display Red Locked QR&lt;br&gt;Ticket Warning" style="ellipse;whiteSpace=wrap;html=1;fillColor=#FFF2CC;strokeColor=#D6B656;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="840" y="430" width="190" height="50" as="geometry" />
        </mxCell>
        <mxCell id="uc_ext_stu_3" value="View Live In/Out&lt;br&gt;Attendance Status" style="ellipse;whiteSpace=wrap;html=1;fillColor=#FFF2CC;strokeColor=#D6B656;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="840" y="490" width="190" height="50" as="geometry" />
        </mxCell>
        <mxCell id="uc_ext_stu_4" value="Show Cash Payment&lt;br&gt;Remittance Guide" style="ellipse;whiteSpace=wrap;html=1;fillColor=#FFF2CC;strokeColor=#D6B656;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="840" y="550" width="190" height="50" as="geometry" />
        </mxCell>

        <!-- Associations -->
        <mxCell id="edge_stu_1" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_stu" target="uc_stu_1"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="edge_stu_2" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_stu" target="uc_stu_2"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="edge_stu_3" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_stu" target="uc_stu_3"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="edge_stu_4" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_stu" target="uc_stu_4"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="edge_stu_5" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_stu" target="uc_stu_5"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="edge_stu_6" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_stu" target="uc_stu_6"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="edge_stu_7" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_stu" target="uc_stu_7"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="edge_stu_8" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_stu" target="uc_stu_8"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="edge_stu_9" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_stu" target="uc_stu_9"><mxGeometry relative="1" as="geometry" /></mxCell>

        <!-- Include Relationships -->
        <mxCell id="inc_stu_1" value="&amp;lt;&amp;lt;include&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#900C3F;fontColor=#900C3F;" edge="1" parent="1" source="uc_stu_1" target="uc_inc_stu_1"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="inc_stu_2" value="&amp;lt;&amp;lt;include&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#900C3F;fontColor=#900C3F;" edge="1" parent="1" source="uc_stu_3" target="uc_inc_stu_2"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="inc_stu_3" value="&amp;lt;&amp;lt;include&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#900C3F;fontColor=#900C3F;" edge="1" parent="1" source="uc_stu_6" target="uc_inc_stu_3"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="inc_stu_4" value="&amp;lt;&amp;lt;include&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#900C3F;fontColor=#900C3F;" edge="1" parent="1" source="uc_stu_7" target="uc_inc_stu_4"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="inc_stu_5" value="&amp;lt;&amp;lt;include&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#900C3F;fontColor=#900C3F;" edge="1" parent="1" source="uc_stu_8" target="uc_inc_stu_5"><mxGeometry relative="1" as="geometry" /></mxCell>

        <!-- Extend Relationships -->
        <mxCell id="ext_stu_1" value="&amp;lt;&amp;lt;extend&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#856404;fontColor=#856404;" edge="1" parent="1" source="uc_ext_stu_1" target="uc_stu_2"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="ext_stu_2" value="&amp;lt;&amp;lt;extend&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#856404;fontColor=#856404;" edge="1" parent="1" source="uc_ext_stu_2" target="uc_stu_6"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="ext_stu_3" value="&amp;lt;&amp;lt;extend&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#856404;fontColor=#856404;" edge="1" parent="1" source="uc_ext_stu_3" target="uc_stu_6"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="ext_stu_4" value="&amp;lt;&amp;lt;extend&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#856404;fontColor=#856404;" edge="1" parent="1" source="uc_ext_stu_4" target="uc_stu_7"><mxGeometry relative="1" as="geometry" /></mxCell>
  `;
}

// Generate drawio XML content for Scanner
function getScannerDrawioContent() {
  return `
        <!-- System Boundary -->
        <mxCell id="sys_scn" value="STI Sync Mobile - Student Scanner Officer Subsystem Boundary" style="shape=umlFrame;whiteSpace=wrap;html=1;width=380;height=30;boundedLbl=1;verticalAlign=top;align=left;spacingLeft=10;fillColor=none;strokeColor=#E67E22;strokeWidth=2;" vertex="1" parent="1">
          <mxGeometry x="190" y="40" width="880" height="740" as="geometry" />
        </mxCell>

        <!-- Actor -->
        <mxCell id="act_scn" value="Student Scanner&lt;br&gt;&lt;b&gt;Officer (Mobile)&lt;/b&gt;" style="shape=umlActor;verticalLabelPosition=bottom;verticalAlign=top;html=1;outlineConnect=0;fillColor=#FFE6CC;strokeColor=#D79B00;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="60" y="320" width="50" height="90" as="geometry" />
        </mxCell>

        <!-- Base Use Cases -->
        <mxCell id="uc_scn_1" value="Authenticate &amp;amp; Open&lt;br&gt;Scanner Mode" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="100" width="200" height="60" as="geometry" />
        </mxCell>
        <mxCell id="uc_scn_2" value="Pre-Cache Event Roster&lt;br&gt;to SQLite (Drift)" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="200" width="200" height="60" as="geometry" />
        </mxCell>
        <mxCell id="uc_scn_3" value="Scan QR Ticket&lt;br&gt;via Camera" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="310" width="200" height="60" as="geometry" />
        </mxCell>
        <mxCell id="uc_scn_4" value="Record Manual / Flagged&lt;br&gt;Attendance Entry" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="440" width="200" height="60" as="geometry" />
        </mxCell>
        <mxCell id="uc_scn_5" value="View Real-Time Gate&lt;br&gt;Attendance Logs" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="550" width="200" height="60" as="geometry" />
        </mxCell>
        <mxCell id="uc_scn_6" value="Synchronize Data&lt;br&gt;with Cloud Firestore" style="ellipse;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;strokeWidth=1.5;fontStyle=1;" vertex="1" parent="1">
          <mxGeometry x="250" y="660" width="200" height="60" as="geometry" />
        </mxCell>

        <!-- Included Use Cases -->
        <mxCell id="uc_inc_scn_1" value="Validate Scanner Role&lt;br&gt;&amp;amp; Session Permissions" style="ellipse;whiteSpace=wrap;html=1;fillColor=#F8CECC;strokeColor=#B85450;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="610" y="100" width="190" height="50" as="geometry" />
        </mxCell>
        <mxCell id="uc_inc_scn_2" value="Execute 6-Step Validation&lt;br&gt;Pipeline" style="ellipse;whiteSpace=wrap;html=1;fillColor=#F8CECC;strokeColor=#B85450;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="610" y="270" width="190" height="50" as="geometry" />
        </mxCell>
        <mxCell id="uc_inc_scn_3" value="Evaluate Grace Period&lt;br&gt;&amp;amp; Late Status" style="ellipse;whiteSpace=wrap;html=1;fillColor=#F8CECC;strokeColor=#B85450;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="610" y="330" width="190" height="50" as="geometry" />
        </mxCell>
        <mxCell id="uc_inc_scn_4" value="Save Offline Attendance&lt;br&gt;Record to SQLite" style="ellipse;whiteSpace=wrap;html=1;fillColor=#F8CECC;strokeColor=#B85450;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="610" y="390" width="190" height="50" as="geometry" />
        </mxCell>
        <mxCell id="uc_inc_scn_5" value="Batch Upload Unsynced&lt;br&gt;SQLite Records" style="ellipse;whiteSpace=wrap;html=1;fillColor=#F8CECC;strokeColor=#B85450;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="610" y="660" width="190" height="50" as="geometry" />
        </mxCell>

        <!-- Extended Use Cases -->
        <mxCell id="uc_ext_scn_1" value="Display Visual Result Overlay&lt;br&gt;(Present/Late/Duplicate/Closed)" style="ellipse;whiteSpace=wrap;html=1;fillColor=#FFF2CC;strokeColor=#D6B656;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="840" y="330" width="200" height="50" as="geometry" />
        </mxCell>
        <mxCell id="uc_ext_scn_2" value="Add Walk-in / Unknown&lt;br&gt;Attendee to Session" style="ellipse;whiteSpace=wrap;html=1;fillColor=#FFF2CC;strokeColor=#D6B656;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="610" y="445" width="190" height="50" as="geometry" />
        </mxCell>
        <mxCell id="uc_ext_scn_3" value="Inspect &amp;amp; Resolve&lt;br&gt;Sync Conflicts" style="ellipse;whiteSpace=wrap;html=1;fillColor=#FFF2CC;strokeColor=#D6B656;strokeWidth=1.5;" vertex="1" parent="1">
          <mxGeometry x="840" y="660" width="190" height="50" as="geometry" />
        </mxCell>

        <!-- Associations -->
        <mxCell id="edge_scn_1" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_scn" target="uc_scn_1"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="edge_scn_2" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_scn" target="uc_scn_2"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="edge_scn_3" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_scn" target="uc_scn_3"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="edge_scn_4" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_scn" target="uc_scn_4"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="edge_scn_5" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_scn" target="uc_scn_5"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="edge_scn_6" style="endArrow=none;html=1;rounded=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;strokeWidth=1.5;strokeColor=#333333;" edge="1" parent="1" source="act_scn" target="uc_scn_6"><mxGeometry relative="1" as="geometry" /></mxCell>

        <!-- Include Relationships -->
        <mxCell id="inc_scn_1" value="&amp;lt;&amp;lt;include&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#900C3F;fontColor=#900C3F;" edge="1" parent="1" source="uc_scn_1" target="uc_inc_scn_1"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="inc_scn_2" value="&amp;lt;&amp;lt;include&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#900C3F;fontColor=#900C3F;" edge="1" parent="1" source="uc_scn_3" target="uc_inc_scn_2"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="inc_scn_3" value="&amp;lt;&amp;lt;include&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#900C3F;fontColor=#900C3F;" edge="1" parent="1" source="uc_scn_3" target="uc_inc_scn_3"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="inc_scn_4" value="&amp;lt;&amp;lt;include&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#900C3F;fontColor=#900C3F;" edge="1" parent="1" source="uc_scn_3" target="uc_inc_scn_4"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="inc_scn_5" value="&amp;lt;&amp;lt;include&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#900C3F;fontColor=#900C3F;" edge="1" parent="1" source="uc_scn_6" target="uc_inc_scn_5"><mxGeometry relative="1" as="geometry" /></mxCell>

        <!-- Extend Relationships -->
        <mxCell id="ext_scn_1" value="&amp;lt;&amp;lt;extend&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#856404;fontColor=#856404;" edge="1" parent="1" source="uc_ext_scn_1" target="uc_scn_3"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="ext_scn_2" value="&amp;lt;&amp;lt;extend&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#856404;fontColor=#856404;" edge="1" parent="1" source="uc_ext_scn_2" target="uc_scn_4"><mxGeometry relative="1" as="geometry" /></mxCell>
        <mxCell id="ext_scn_3" value="&amp;lt;&amp;lt;extend&amp;gt;&amp;gt;" style="html=1;verticalAlign=bottom;labelBackgroundColor=none;endArrow=open;endFill=0;dashed=1;rounded=0;strokeWidth=1.2;strokeColor=#856404;fontColor=#856404;" edge="1" parent="1" source="uc_ext_scn_3" target="uc_scn_6"><mxGeometry relative="1" as="geometry" /></mxCell>
  `;
}

// Master Drawio file containing all 4 tabs
const masterDrawioXml = createDrawioXml([
  { id: 'diag_admin', name: 'SAO Administrator', content: getAdminDrawioContent() },
  { id: 'diag_officer', name: 'Organization Officer', content: getOfficerDrawioContent() },
  { id: 'diag_student', name: 'Student Mobile User', content: getStudentDrawioContent() },
  { id: 'diag_scanner', name: 'Student Scanner Officer', content: getScannerDrawioContent() }
]);

// Single-page drawio files
const adminDrawioXml = createDrawioXml([{ id: 'diag_admin', name: 'SAO Administrator', content: getAdminDrawioContent() }]);
const officerDrawioXml = createDrawioXml([{ id: 'diag_officer', name: 'Organization Officer', content: getOfficerDrawioContent() }]);
const studentDrawioXml = createDrawioXml([{ id: 'diag_student', name: 'Student Mobile User', content: getStudentDrawioContent() }]);
const scannerDrawioXml = createDrawioXml([{ id: 'diag_scanner', name: 'Student Scanner Officer', content: getScannerDrawioContent() }]);

const drawioFiles = [
  { name: 'sti-sync-all-actors.drawio', content: masterDrawioXml },
  { name: 'admin-use-case-diagram.drawio', content: adminDrawioXml },
  { name: 'officer-use-case-diagram.drawio', content: officerDrawioXml },
  { name: 'student-use-case-diagram.drawio', content: studentDrawioXml },
  { name: 'scanner-use-case-diagram.drawio', content: scannerDrawioXml }
];

targetDirs.forEach(dir => {
  drawioFiles.forEach(file => {
    fs.writeFileSync(path.join(dir, file.name), file.content, 'utf8');
  });
});
console.log('Saved all Draw.io (.drawio) files.');

// ==========================================
// 3. STANDALONE VECTOR SVG GENERATION (.svg)
// ==========================================

function generateSvgDiagram(actorName, actorColor, systemTitle, baseCases, incCases, extCases, associations, incLinks, extLinks) {
  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1150 820" width="100%" height="100%" style="background-color: #FFFFFF; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;">
  <defs>
    <!-- Shadow Filter -->
    <filter id="dropShadow" x="-10%" y="-10%" width="130%" height="130%">
      <feDropShadow dx="2" dy="3" stdDeviation="3" flood-opacity="0.12" />
    </filter>
    
    <!-- Open Arrow Marker for Include/Extend -->
    <marker id="arrowInc" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 8 5 L 0 9" fill="none" stroke="#D9383A" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" />
    </marker>
    <marker id="arrowExt" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 8 5 L 0 9" fill="none" stroke="#D39E00" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" />
    </marker>
  </defs>

  <!-- Title Header -->
  <text x="40" y="35" font-size="20" font-weight="bold" fill="#001A4D">${systemTitle}</text>
  <text x="40" y="55" font-size="12" fill="#666666">UML 2.5 Use Case Diagram Standard (Actors, Associations, &lt;&lt;include&gt;&gt;, &lt;&lt;extend&gt;&gt;)</text>

  <!-- System Boundary Box -->
  <rect x="220" y="70" width="890" height="720" rx="8" ry="8" fill="#F8FAFC" stroke="#94A3B8" stroke-width="2" stroke-dasharray="0" />
  <rect x="220" y="70" width="890" height="32" rx="8" ry="8" fill="#E2E8F0" />
  <text x="235" y="92" font-size="13" font-weight="bold" fill="#334155">${systemTitle} — System Boundary</text>

  <!-- Actor Stick Figure & Label -->
  <g transform="translate(45, 330)">
    <!-- Head -->
    <circle cx="50" cy="30" r="18" fill="${actorColor}" stroke="#1E293B" stroke-width="2.5" />
    <!-- Body -->
    <line x1="50" y1="48" x2="50" y2="105" stroke="#1E293B" stroke-width="2.5" stroke-linecap="round" />
    <!-- Arms -->
    <line x1="15" y1="70" x2="85" y2="70" stroke="#1E293B" stroke-width="2.5" stroke-linecap="round" />
    <!-- Left Leg -->
    <line x1="50" y1="105" x2="22" y2="155" stroke="#1E293B" stroke-width="2.5" stroke-linecap="round" />
    <!-- Right Leg -->
    <line x1="50" y1="105" x2="78" y2="155" stroke="#1E293B" stroke-width="2.5" stroke-linecap="round" />
    <!-- Actor Label -->
    <text x="50" y="180" text-anchor="middle" font-size="14" font-weight="bold" fill="#0F172A">${actorName}</text>
  </g>

  <!-- Association Lines (Actor to Base Cases) -->
  <g stroke="#334155" stroke-width="1.8">
    ${associations.map(a => `<line x1="110" y1="400" x2="${a.x}" y2="${a.y}" />`).join('\n    ')}
  </g>

  <!-- Include Links (Base Cases to Included Cases) -->
  <g stroke="#D9383A" stroke-width="1.6" stroke-dasharray="6,4" marker-end="url(#arrowInc)">
    ${incLinks.map(l => `<line x1="${l.x1}" y1="${l.y1}" x2="${l.x2}" y2="${l.y2}" />`).join('\n    ')}
  </g>
  <g font-size="11" font-weight="bold" fill="#D9383A" text-anchor="middle">
    ${incLinks.map(l => `<text x="${(l.x1 + l.x2)/2}" y="${(l.y1 + l.y2)/2 - 5}">&lt;&lt;include&gt;&gt;</text>`).join('\n    ')}
  </g>

  <!-- Extend Links (Extending Cases to Base Cases) -->
  <g stroke="#D39E00" stroke-width="1.6" stroke-dasharray="6,4" marker-end="url(#arrowExt)">
    ${extLinks.map(l => `<line x1="${l.x1}" y1="${l.y1}" x2="${l.x2}" y2="${l.y2}" />`).join('\n    ')}
  </g>
  <g font-size="11" font-weight="bold" fill="#B45309" text-anchor="middle">
    ${extLinks.map(l => `<text x="${(l.x1 + l.x2)/2}" y="${(l.y1 + l.y2)/2 - 5}">&lt;&lt;extend&gt;&gt;</text>`).join('\n    ')}
  </g>

  <!-- Base Use Cases (Blue Ovals) -->
  <g filter="url(#dropShadow)">
    ${baseCases.map(bc => `
    <g transform="translate(${bc.x}, ${bc.y})">
      <ellipse cx="100" cy="27" rx="100" ry="27" fill="#DAE8FC" stroke="#6C8EBF" stroke-width="2" />
      <text x="100" y="${bc.lines.length > 1 ? 22 : 32}" text-anchor="middle" font-size="12" font-weight="bold" fill="#001A4D">
        ${bc.lines.map((ln, i) => `<tspan x="100" dy="${i === 0 ? 0 : 15}">${ln}</tspan>`).join('')}
      </text>
    </g>`).join('')}
  </g>

  <!-- Included Use Cases (Pink/Red Ovals) -->
  <g filter="url(#dropShadow)">
    ${incCases.map(ic => `
    <g transform="translate(${ic.x}, ${ic.y})">
      <ellipse cx="95" cy="25" rx="95" ry="25" fill="#F8CECC" stroke="#D9383A" stroke-width="1.8" />
      <text x="95" y="${ic.lines.length > 1 ? 21 : 30}" text-anchor="middle" font-size="11" fill="#900C3F">
        ${ic.lines.map((ln, i) => `<tspan x="95" dy="${i === 0 ? 0 : 14}">${ln}</tspan>`).join('')}
      </text>
    </g>`).join('')}
  </g>

  <!-- Extended Use Cases (Yellow/Amber Ovals) -->
  <g filter="url(#dropShadow)">
    ${extCases.map(ec => `
    <g transform="translate(${ec.x}, ${ec.y})">
      <ellipse cx="95" cy="25" rx="95" ry="25" fill="#FFF2CC" stroke="#D39E00" stroke-width="1.8" />
      <text x="95" y="${ec.lines.length > 1 ? 21 : 30}" text-anchor="middle" font-size="11" fill="#856404">
        ${ec.lines.map((ln, i) => `<tspan x="95" dy="${i === 0 ? 0 : 14}">${ln}</tspan>`).join('')}
      </text>
    </g>`).join('')}
  </g>

  <!-- Legend -->
  <g transform="translate(40, 725)">
    <rect x="0" y="0" width="160" height="65" rx="5" ry="5" fill="#FFFFFF" stroke="#CBD5E1" stroke-width="1" />
    <ellipse cx="20" cy="18" rx="10" ry="6" fill="#DAE8FC" stroke="#6C8EBF" stroke-width="1.5" />
    <text x="38" y="22" font-size="10" font-weight="bold" fill="#001A4D">Base Use Case</text>
    <ellipse cx="20" cy="35" rx="10" ry="6" fill="#F8CECC" stroke="#D9383A" stroke-width="1.5" />
    <text x="38" y="39" font-size="10" fill="#900C3F">&lt;&lt;include&gt;&gt; Case</text>
    <ellipse cx="20" cy="52" rx="10" ry="6" fill="#FFF2CC" stroke="#D39E00" stroke-width="1.5" />
    <text x="38" y="56" font-size="10" fill="#856404">&lt;&lt;extend&gt;&gt; Case</text>
  </g>
</svg>`;
}

// Data for Admin SVG
const adminSvgData = {
  actorName: 'SAO / SAS Administrator',
  actorColor: '#FFF2CC',
  systemTitle: 'STI Sync Web — SAO Administrator Use Case Diagram',
  baseCases: [
    { x: 260, y: 110, lines: ['Log In to Admin Portal'] },
    { x: 260, y: 180, lines: ['Manage Academic Semesters', '& Rollover Engine'] },
    { x: 260, y: 255, lines: ['Manage Student Registry', '& Lifecycle'] },
    { x: 260, y: 330, lines: ['Govern Student Organizations', '& Advisers'] },
    { x: 260, y: 405, lines: ['Create Institutional', 'SAS Event'] },
    { x: 260, y: 480, lines: ['Review Club Event Proposals'] },
    { x: 260, y: 555, lines: ['Audit Financial Liquidations'] },
    { x: 260, y: 630, lines: ['Manage Certificate', 'Templates & Issuance'] },
    { x: 260, y: 705, lines: ['Monitor System Audit Logs'] }
  ],
  incCases: [
    { x: 590, y: 155, lines: ['Validate Term & Execute', 'Track Rollover'] },
    { x: 590, y: 215, lines: ['Record Immutable', 'Audit Log Entry'] },
    { x: 590, y: 275, lines: ['Verify Student ID &', 'Selfie Photo Match'] },
    { x: 590, y: 375, lines: ['Configure Multi-Session', 'Time Windows'] },
    { x: 590, y: 435, lines: ['Recruit Cross-Org', 'Scanner Officers'] },
    { x: 590, y: 495, lines: ['Calculate Suggested Fee', '& Budget Pools'] },
    { x: 590, y: 630, lines: ['Generate Verification', 'QR Hash'] }
  ],
  extCases: [
    { x: 860, y: 245, lines: ['Check Financial Debt', 'Clearance Pre-Flight'] },
    { x: 860, y: 305, lines: ['Permanently Purge', 'Student Archive'] },
    { x: 860, y: 405, lines: ['Enforce Red QR Lock', 'Gate Policy'] },
    { x: 590, y: 555, lines: ['Request Proposal Revision', 'with Feedback Notes'] }
  ],
  associations: [
    { x: 260, y: 137 },
    { x: 260, y: 207 },
    { x: 260, y: 282 },
    { x: 260, y: 357 },
    { x: 260, y: 432 },
    { x: 260, y: 507 },
    { x: 260, y: 582 },
    { x: 260, y: 657 },
    { x: 260, y: 732 }
  ],
  incLinks: [
    { x1: 460, y1: 207, x2: 590, y2: 180 },
    { x1: 460, y1: 207, x2: 590, y2: 240 },
    { x1: 460, y1: 282, x2: 590, y2: 300 },
    { x1: 460, y1: 432, x2: 590, y2: 400 },
    { x1: 460, y1: 432, x2: 590, y2: 460 },
    { x1: 460, y1: 432, x2: 590, y2: 520 },
    { x1: 460, y1: 657, x2: 590, y2: 655 }
  ],
  extLinks: [
    { x1: 860, y1: 270, x2: 460, y2: 282 },
    { x1: 860, y1: 330, x2: 460, y2: 282 },
    { x1: 860, y1: 430, x2: 460, y2: 432 },
    { x1: 590, y1: 580, x2: 460, y2: 507 }
  ]
};

// Data for Officer SVG
const officerSvgData = {
  actorName: 'Organization Officer',
  actorColor: '#E1D5E7',
  systemTitle: 'STI Sync Web — Organization Officer Use Case Diagram',
  baseCases: [
    { x: 260, y: 110, lines: ['Log In to Officer Portal'] },
    { x: 260, y: 180, lines: ['Create Event Proposal'] },
    { x: 260, y: 255, lines: ['Manage Member Directory'] },
    { x: 260, y: 330, lines: ['Generate Member Dues', '& Payables'] },
    { x: 260, y: 405, lines: ['Record Cash Payment'] },
    { x: 260, y: 480, lines: ['Control QR Ticket', 'Gate Status'] },
    { x: 260, y: 555, lines: ['Submit Financial Liquidation'] },
    { x: 260, y: 630, lines: ['Request & Generate', 'Certificates'] },
    { x: 260, y: 705, lines: ['Post Announcements'] }
  ],
  incCases: [
    { x: 590, y: 155, lines: ['Auto-Bind Active', 'Hosting Organization'] },
    { x: 590, y: 215, lines: ['Assign Scanners from', 'Club Officer Roster'] },
    { x: 590, y: 330, lines: ['Batch Generate', 'Payable Documents'] },
    { x: 590, y: 405, lines: ['Unlock Student Mobile', 'QR Ticket in Real-Time'] },
    { x: 590, y: 555, lines: ['Upload Receipts to', 'Cloudinary Storage'] },
    { x: 590, y: 630, lines: ['Filter Verified Present', 'Attendees Only'] }
  ],
  extCases: [
    { x: 590, y: 270, lines: ['Appoint / Promote Member', 'to Officer Position'] },
    { x: 590, y: 480, lines: ['Manual Gate Ticket', 'Override Unlock'] },
    { x: 860, y: 555, lines: ['Resubmit Revised', 'Liquidation Report'] }
  ],
  associations: [
    { x: 260, y: 137 },
    { x: 260, y: 207 },
    { x: 260, y: 282 },
    { x: 260, y: 357 },
    { x: 260, y: 432 },
    { x: 260, y: 507 },
    { x: 260, y: 582 },
    { x: 260, y: 657 },
    { x: 260, y: 732 }
  ],
  incLinks: [
    { x1: 460, y1: 207, x2: 590, y2: 180 },
    { x1: 460, y1: 207, x2: 590, y2: 240 },
    { x1: 460, y1: 357, x2: 590, y2: 355 },
    { x1: 460, y1: 432, x2: 590, y2: 430 },
    { x1: 460, y1: 582, x2: 590, y2: 580 },
    { x1: 460, y1: 657, x2: 590, y2: 655 }
  ],
  extLinks: [
    { x1: 590, y1: 295, x2: 460, y2: 282 },
    { x1: 590, y1: 505, x2: 460, y2: 507 },
    { x1: 860, y1: 580, x2: 460, y2: 582 }
  ]
};

// Data for Student SVG
const studentSvgData = {
  actorName: 'Student User (Mobile)',
  actorColor: '#D5E8D4',
  systemTitle: 'STI Sync Mobile — Student User Use Case Diagram',
  baseCases: [
    { x: 260, y: 110, lines: ['Complete 6-Step Registration'] },
    { x: 260, y: 180, lines: ['Log In to Mobile App'] },
    { x: 260, y: 255, lines: ['Complete Semester', 'Re-Enrollment'] },
    { x: 260, y: 330, lines: ['Browse & Filter Events'] },
    { x: 260, y: 405, lines: ['View Event Details & Sessions'] },
    { x: 260, y: 480, lines: ['Access Dynamic QR', 'Entry Ticket'] },
    { x: 260, y: 555, lines: ['View Payables & Fines'] },
    { x: 260, y: 630, lines: ['View & Download', 'Certificates'] },
    { x: 260, y: 705, lines: ['Manage Student Profile'] }
  ],
  incCases: [
    { x: 590, y: 110, lines: ['Upload 2x2 Photo &', 'School ID Card'] },
    { x: 590, y: 255, lines: ['Validate Track Active', 'Academic Term'] },
    { x: 590, y: 455, lines: ['Generate Signed QR', 'Ticket Payload'] },
    { x: 590, y: 555, lines: ['Itemize Billed Amount,', 'Paid & Balance'] },
    { x: 590, y: 630, lines: ['Verify Certificate QR', 'Code Authenticity'] }
  ],
  extCases: [
    { x: 590, y: 180, lines: ['Show Pending Verification', 'Status Screen'] },
    { x: 860, y: 450, lines: ['Display Red Locked QR', 'Ticket Warning'] },
    { x: 860, y: 510, lines: ['View Live In/Out', 'Attendance Status'] },
    { x: 860, y: 570, lines: ['Show Cash Payment', 'Remittance Guide'] }
  ],
  associations: [
    { x: 260, y: 137 },
    { x: 260, y: 207 },
    { x: 260, y: 282 },
    { x: 260, y: 357 },
    { x: 260, y: 432 },
    { x: 260, y: 507 },
    { x: 260, y: 582 },
    { x: 260, y: 657 },
    { x: 260, y: 732 }
  ],
  incLinks: [
    { x1: 460, y1: 137, x2: 590, y2: 135 },
    { x1: 460, y1: 282, x2: 590, y2: 280 },
    { x1: 460, y1: 507, x2: 590, y2: 480 },
    { x1: 460, y1: 582, x2: 590, y2: 580 },
    { x1: 460, y1: 657, x2: 590, y2: 655 }
  ],
  extLinks: [
    { x1: 590, y1: 205, x2: 460, y2: 207 },
    { x1: 860, y1: 475, x2: 460, y2: 507 },
    { x1: 860, y1: 535, x2: 460, y2: 507 },
    { x1: 860, y1: 595, x2: 460, y2: 582 }
  ]
};

// Data for Scanner SVG
const scannerSvgData = {
  actorName: 'Student Scanner Officer',
  actorColor: '#FFE6CC',
  systemTitle: 'STI Sync Mobile — Student Scanner Officer Use Case Diagram',
  baseCases: [
    { x: 260, y: 120, lines: ['Authenticate & Open', 'Scanner Mode'] },
    { x: 260, y: 220, lines: ['Pre-Cache Event Roster', 'to SQLite (Drift)'] },
    { x: 260, y: 330, lines: ['Scan QR Ticket', 'via Camera'] },
    { x: 260, y: 460, lines: ['Record Manual / Flagged', 'Attendance Entry'] },
    { x: 260, y: 570, lines: ['View Real-Time Gate', 'Attendance Logs'] },
    { x: 260, y: 680, lines: ['Synchronize Data', 'with Cloud Firestore'] }
  ],
  incCases: [
    { x: 590, y: 120, lines: ['Validate Scanner Role', '& Session Permissions'] },
    { x: 590, y: 290, lines: ['Execute 6-Step Validation', 'Pipeline'] },
    { x: 590, y: 350, lines: ['Evaluate Grace Period', '& Late Status'] },
    { x: 590, y: 410, lines: ['Save Offline Attendance', 'Record to SQLite'] },
    { x: 590, y: 680, lines: ['Batch Upload Unsynced', 'SQLite Records'] }
  ],
  extCases: [
    { x: 860, y: 350, lines: ['Display Visual Result Overlay', '(Present/Late/Duplicate/Closed)'] },
    { x: 590, y: 460, lines: ['Add Walk-in / Unknown', 'Attendee to Session'] },
    { x: 860, y: 680, lines: ['Inspect & Resolve', 'Sync Conflicts'] }
  ],
  associations: [
    { x: 260, y: 147 },
    { x: 260, y: 247 },
    { x: 260, y: 357 },
    { x: 260, y: 487 },
    { x: 260, y: 597 },
    { x: 260, y: 707 }
  ],
  incLinks: [
    { x1: 460, y1: 147, x2: 590, y2: 145 },
    { x1: 460, y1: 357, x2: 590, y2: 315 },
    { x1: 460, y1: 357, x2: 590, y2: 375 },
    { x1: 460, y1: 357, x2: 590, y2: 435 },
    { x1: 460, y1: 707, x2: 590, y2: 705 }
  ],
  extLinks: [
    { x1: 860, y1: 375, x2: 460, y2: 357 },
    { x1: 590, y1: 485, x2: 460, y2: 487 },
    { x1: 860, y1: 705, x2: 460, y2: 707 }
  ]
};

const svgFiles = [
  { name: 'admin-use-case-diagram.svg', content: generateSvgDiagram(adminSvgData.actorName, adminSvgData.actorColor, adminSvgData.systemTitle, adminSvgData.baseCases, adminSvgData.incCases, adminSvgData.extCases, adminSvgData.associations, adminSvgData.incLinks, adminSvgData.extLinks) },
  { name: 'officer-use-case-diagram.svg', content: generateSvgDiagram(officerSvgData.actorName, officerSvgData.actorColor, officerSvgData.systemTitle, officerSvgData.baseCases, officerSvgData.incCases, officerSvgData.extCases, officerSvgData.associations, officerSvgData.incLinks, officerSvgData.extLinks) },
  { name: 'student-use-case-diagram.svg', content: generateSvgDiagram(studentSvgData.actorName, studentSvgData.actorColor, studentSvgData.systemTitle, studentSvgData.baseCases, studentSvgData.incCases, studentSvgData.extCases, studentSvgData.associations, studentSvgData.incLinks, studentSvgData.extLinks) },
  { name: 'scanner-use-case-diagram.svg', content: generateSvgDiagram(scannerSvgData.actorName, scannerSvgData.actorColor, scannerSvgData.systemTitle, scannerSvgData.baseCases, scannerSvgData.incCases, scannerSvgData.extCases, scannerSvgData.associations, scannerSvgData.incLinks, scannerSvgData.extLinks) }
];

targetDirs.forEach(dir => {
  svgFiles.forEach(file => {
    fs.writeFileSync(path.join(dir, file.name), file.content, 'utf8');
  });
});
console.log('Saved all Scalable Vector Graphics (.svg) files.');
