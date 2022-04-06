*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Selenium    auto_close=${FALSE}
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.FileSystem
Library    RPA.Archive
Library    RPA.Dialogs
Library    RPA.Robocloud.Secrets

*** Keywords ***
Initialization
    Create Directory    ${OUTPUT_DIR}${/}RECEIPTS    exist_ok=TRUE
    Create Directory    ${OUTPUT_DIR}${/}SCREENSHOTS    exist_ok=TRUE
    Remove File    ${OUTPUT_DIR}${/}output.zip    missing_ok=TRUE

Dialog to read input file URL
    Add heading    Order processing bot    
    Add text input    file_url    label=Please enter the input file URL
    ${dialog}=   Show dialog
    ${results}=   Wait dialog     ${dialog}
    [Return]    ${results.file_url}

Save Robot Screenshot
    [Arguments]    ${filename}
    Screenshot    robot-preview-image    ${OUTPUT_DIR}${/}SCREENSHOTS${/}${filename}.png
    [Return]    ${OUTPUT_DIR}${/}SCREENSHOTS${/}${filename}.png

Save Receipt PDF
    [Arguments]    ${filename}
    ${html_element}=    Get Element Attribute    id:receipt    innerHTML 
    Html To Pdf    ${html_element}    ${OUTPUT_DIR}${/}RECEIPTS${/}${filename}.pdf
    [Return]    ${OUTPUT_DIR}${/}RECEIPTS${/}${filename}.pdf

Open Robot_Order website
    [Arguments]    ${website_url}
    Open Available Browser    ${website_url}

Close Browser pop-up
    Wait Until Element Is Visible    css:button.btn.btn-danger
    Click Button    css:button.btn.btn-danger

Download Orders CSV File
    [Arguments]    ${File_url}
    Download    ${File_url}    overwrite=TRUE

Read CSV File into Datatable
    ${InputDT}=    Read table from CSV    ${OUTPUT_DIR}${/}orders.csv
    [Return]    ${InputDT}

Check for submission error
    Click Button    order
    Is Element Visible    order-another    missing_ok=FALSE

Embed screenshot of robot into receipt PDF
    [Arguments]    ${files}    ${receipt}
    Open Pdf    ${receipt}
    Add Files To Pdf    ${files}    ${receipt}    append=TRUE    
    Close Pdf

Fill order your robot form
    [Arguments]    ${InputDT}
    FOR    ${row}    IN    @{InputDT}
        Select From List By Value    head    ${row}[Head]
        Select Radio Button    body    id-body-${row}[Body]
        Input Text    xpath://label[text()="3. Legs:"]//following-sibling::input[1]    ${row}[Legs]
        Input Text    address    ${row}[Address]
        Click Button    preview
        Wait Until Keyword Succeeds    5x    3 s    Check for submission error
        ${Screenshot}=    Save Robot Screenshot    ${row}[Order number]
        ${receipt}=    Save Receipt PDF    ${row}[Order number]
        ${Files}=    Create List    ${Screenshot}:format=A4,align=center
        Embed screenshot of robot into receipt Pdf    ${Files}    ${receipt}
        Click Button    order-another
        Close Browser pop-up
    END

Create output ZIP file
    Archive Folder With Zip    ${OUTPUT_DIR}${/}RECEIPTS    output.zip

Clear output files
    Empty Directory    ${OUTPUT_DIR}${/}RECEIPTS
    Empty Directory    ${OUTPUT_DIR}${/}SCREENSHOTS

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Initialization
    ${Secret}=    Get Secret    L2_Training
    ${FileURL}=    Dialog to read input file URL
    Open Robot_Order website    ${Secret}[WebsiteUrl]
    Close Browser pop-up
    Download Orders CSV File    ${FileURL}
    ${InputDT}=    Read CSV File into Datatable
    Fill order your robot form    ${InputDT}
    Create output ZIP file
    [Teardown]    Clear output files