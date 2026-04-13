"""Capture screenshots from the Django app for the rapport."""
import os
import time
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.edge.service import Service as EdgeService
from selenium.webdriver.edge.options import Options as EdgeOptions

BASE_URL = "http://127.0.0.1:8000"
SCREENSHOT_DIR = os.path.join(os.path.dirname(__file__), "screenshots")
os.makedirs(SCREENSHOT_DIR, exist_ok=True)

def get_driver():
    options = EdgeOptions()
    options.add_argument("--headless=new")
    options.add_argument("--window-size=1400,900")
    options.add_argument("--disable-gpu")
    options.add_argument("--no-sandbox")
    driver = webdriver.Edge(options=options)
    return driver

def login(driver, username, password):
    driver.get(f"{BASE_URL}/login/")
    time.sleep(1)
    driver.find_element(By.NAME, "username").clear()
    driver.find_element(By.NAME, "username").send_keys(username)
    driver.find_element(By.NAME, "password").clear()
    driver.find_element(By.NAME, "password").send_keys(password)
    driver.find_element(By.CSS_SELECTOR, "button[type='submit']").click()
    time.sleep(2)

def screenshot(driver, name):
    path = os.path.join(SCREENSHOT_DIR, f"{name}.png")
    driver.save_screenshot(path)
    print(f"  -> {name}.png")

def capture_admin(driver):
    print("\n=== ADMIN ===")
    login(driver, "admin", "admin123")

    screenshot(driver, "admin_dashboard")

    driver.get(f"{BASE_URL}/etudiants/")
    time.sleep(2)
    screenshot(driver, "admin_etudiants")

    driver.get(f"{BASE_URL}/enseignants/")
    time.sleep(2)
    screenshot(driver, "admin_enseignants")

    driver.get(f"{BASE_URL}/seances/")
    time.sleep(2)
    screenshot(driver, "admin_seances")

    driver.get(f"{BASE_URL}/absences/")
    time.sleep(2)
    screenshot(driver, "admin_absences")

    driver.get(f"{BASE_URL}/absences/marquer/")
    time.sleep(2)
    screenshot(driver, "admin_marquer_absences")

    driver.get(f"{BASE_URL}/justificatifs/")
    time.sleep(2)
    screenshot(driver, "admin_justificatifs")

    driver.get(f"{BASE_URL}/stats/groupes/")
    time.sleep(2)
    screenshot(driver, "admin_stats_groupes")

    driver.get(f"{BASE_URL}/stats/matieres/")
    time.sleep(2)
    screenshot(driver, "admin_stats_matieres")

    driver.get(f"{BASE_URL}/utilisateurs/")
    time.sleep(2)
    screenshot(driver, "admin_utilisateurs")

    driver.get(f"{BASE_URL}/traitements/")
    time.sleep(2)
    screenshot(driver, "admin_traitements")

    driver.get(f"{BASE_URL}/audit/")
    time.sleep(2)
    screenshot(driver, "admin_audit")

    # Etudiant detail
    driver.get(f"{BASE_URL}/etudiants/")
    time.sleep(1)
    try:
        link = driver.find_element(By.CSS_SELECTOR, "a.btn-outline-primary")
        link.click()
        time.sleep(2)
        screenshot(driver, "admin_etudiant_detail")
    except:
        pass

    driver.get(f"{BASE_URL}/logout/")
    time.sleep(1)

def capture_enseignant(driver):
    print("\n=== ENSEIGNANT ===")
    login(driver, "enseignant1", "ens12345")

    screenshot(driver, "enseignant_dashboard")

    driver.get(f"{BASE_URL}/absences/")
    time.sleep(2)
    screenshot(driver, "enseignant_absences")

    driver.get(f"{BASE_URL}/etudiants/")
    time.sleep(2)
    screenshot(driver, "enseignant_etudiants")

    driver.get(f"{BASE_URL}/seances/")
    time.sleep(2)
    screenshot(driver, "enseignant_seances")

    driver.get(f"{BASE_URL}/stats/groupes/")
    time.sleep(2)
    screenshot(driver, "enseignant_stats")

    driver.get(f"{BASE_URL}/logout/")
    time.sleep(1)

def capture_etudiant(driver):
    print("\n=== ETUDIANT ===")
    login(driver, "etudiant1", "etu12345")

    screenshot(driver, "etudiant_dashboard")

    driver.get(f"{BASE_URL}/absences/")
    time.sleep(2)
    screenshot(driver, "etudiant_absences")

    driver.get(f"{BASE_URL}/justificatifs/")
    time.sleep(2)
    screenshot(driver, "etudiant_justificatifs")

    driver.get(f"{BASE_URL}/logout/")
    time.sleep(1)

def capture_login(driver):
    print("\n=== LOGIN ===")
    driver.get(f"{BASE_URL}/login/")
    time.sleep(2)
    screenshot(driver, "page_login")

if __name__ == "__main__":
    driver = get_driver()
    try:
        capture_login(driver)
        capture_admin(driver)
        capture_enseignant(driver)
        capture_etudiant(driver)
        print(f"\nAll screenshots saved to: {SCREENSHOT_DIR}")
    finally:
        driver.quit()
