"""Script: automatization scripted used for searching of new variations of DLG1 and DLG4 genes"""

from selenium import webdriver
from selenium.webdriver.firefox.service import Service as FirefoxService
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time 

# Path to the geckodriver executable
PATH = r"C:\Program Files\Webdrivers_selenium\geckodriver.exe"

# Creating the service object
ser = FirefoxService(executable_path=PATH)

# Keywords to search
DLG1_loss = {
    "T632A" : "Thr632Ala",
    "T567A" : "Thr567Ala",
    "T600A" : "Thr600Ala"
}

# Main code
with webdriver.Firefox(service=ser) as driver:

    # Set up - counter, dictionary lenght
    dict_len = len(DLG1_loss)
    elements = 0

    # Search: google scholar, pubmed - one result, tab to continue
    for variation, full_name in DLG1_loss.items():

        # original window
        original_window = driver.current_window_handle 

        # Setup up wait
        wait = WebDriverWait(driver, 10)
        
        # searching result
        query = f'("DLG1" OR "SAP97") AND ("{variation}" OR "{full_name}")'

        # Navigate to Google Scholar with the query
        driver.get(f'https://scholar.google.com/scholar?q={query}')
    
        time.sleep(3)

        # Switch to new window
        driver.switch_to.new_window('tab')
        driver.switch_to.window(driver.window_handles[1])

        # Wait for the new tab to load
        wait.until(EC.number_of_windows_to_be(2))

        # Navigate to pubmed with the query
        driver.get(f'https://pubmed.ncbi.nlm.nih.gov/?term={query}')

        # Checking fo continuation
        user_input = input(f"Enter quit to end or else to continue {elements} out of {dict_len}: ")

        if user_input != "quit":
            # Close the current window and switch back to the original window
            if elements < dict_len:
                elements += 1
                driver.close()
                driver.switch_to.window(original_window)
            elif elements == dict_len:
                print("All elements done ...")
                print("Ending iteration after 5 seconds")          
                time.sleep(5)
                break
        else:
            print(f"Done elements {elements}/{dict_len}")
            print("Ending program after 3 seconds...")
            time.sleep(3)
            break
