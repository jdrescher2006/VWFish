#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pyotherside
import re
import requests
import json
import sys
import urllib.parse
from urllib.parse import urlsplit

CARNET_USERNAME = ''
CARNET_PASSWORD = ''

HEADERS = { 'Accept': 'application/json, text/plain, */*',
                        'Content-Type': 'application/json;charset=UTF-8',
                        'User-Agent': 'Mozilla/5.0 (Linux; Android 6.0.1; D5803 Build/23.5.A.1.291; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/63.0.3239.111 Mobile Safari/537.36' }


def CarNetLogin(s,email, password):
        fncReturnProgress(1, "Init...")

        AUTHHEADERS = { 'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
                        'User-Agent': 'Mozilla/5.0 (Linux; Android 6.0.1; D5803 Build/23.5.A.1.291; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/63.0.3239.111 Mobile Safari/537.36' }
        auth_base = "https://security.volkswagen.com"
        base = "https://www.volkswagen-car-net.com"

        # Regular expressions to extract data
        csrf_re = re.compile('<meta name="_csrf" content="([^"]*)"/>')
        redurl_re = re.compile('<redirect url="([^"]*)"></redirect>')
        viewstate_re = re.compile('name="javax.faces.ViewState" id="j_id1:javax.faces.ViewState:0" value="([^"]*)"')
        authcode_re = re.compile('code=([^"]*)&')
        authstate_re = re.compile('state=([^"]*)')

        def extract_csrf(r):
                return csrf_re.search(r.text).group(1)

        def extract_redirect_url(r):
                return redurl_re.search(r.text).group(1)

        def extract_view_state(r):
                return viewstate_re.search(r.text).group(1)

        def extract_code(r):
                return authcode_re.search(r).group(1)

        def extract_state(r):
                return authstate_re.search(r).group(1)

        # Request landing page and get CSFR:
        fncReturnProgress(2, "Request landing page and get CSFR")
        r = s.get(base + '/portal/en_GB/web/guest/home')
        if r.status_code != 200:
                return ""
        csrf = extract_csrf(r)
        #fncPrint(csrf)

        # Request login page and get CSRF
        fncReturnProgress(3, "Request login page and get CSRF")
        AUTHHEADERS["Referer"] = base + '/portal'
        AUTHHEADERS["X-CSRF-Token"] = csrf
        r = s.post(base + '/portal/web/guest/home/-/csrftokenhandling/get-login-url',headers=AUTHHEADERS)
        if r.status_code != 200:
            return ""
        #fncPrint("r.text: " + r.text)
        responseData = json.loads(r.text)
        lg_url = responseData.get("loginURL").get("path")
        #fncPrint("lg_url: " + lg_url)

        # no redirect so we can get values we look for
        fncReturnProgress(4, "no redirect so we can get values we look for")
        r = s.get(lg_url, allow_redirects=False, headers=AUTHHEADERS)
        if r.status_code != 302:
            return ""
        ref_url = r.headers.get("location")
        #fncPrint("ref_url: " + ref_url)

        # now get actual login page and get session id and ViewState
        fncReturnProgress(5, "now get actual login page and get session id and ViewState")
        r = s.get(ref_url, headers=AUTHHEADERS)
        if r.status_code != 200:
            return ""
        view_state = extract_view_state(r)
        #fncPrint("view_state: " + view_state)

        # Login with user details
        fncReturnProgress(6, "Login with user details")
        AUTHHEADERS["Faces-Request"] = "partial/ajax"
        AUTHHEADERS["Referer"] = ref_url
        AUTHHEADERS["X-CSRF-Token"] = ''

        post_data = {
                'loginForm': 'loginForm',
                'loginForm:email': email,
                'loginForm:password': password,
                'loginForm:j_idt19': '',
                'javax.faces.ViewState': view_state,
                'javax.faces.source': 'loginForm:submit',
                'javax.faces.partial.event': 'click',
                'javax.faces.partial.execute': 'loginForm:submit loginForm',
                'javax.faces.partial.render': 'loginForm',
                'javax.faces.behavior.event': 'action',
                'javax.faces.partial.ajax': 'true'
        }
        r = s.post(auth_base + '/ap-login/jsf/login.jsf', data=post_data, headers=AUTHHEADERS)
        if r.status_code != 200:
                return ""
        ref_url = extract_redirect_url(r).replace('&amp;', '&')
        #fncPrint("ref_url: " + ref_url)

        # redirect to link from login and extract state and code values
        fncReturnProgress(7, "redirect to link from login")
        r = s.get(ref_url, allow_redirects=False, headers=AUTHHEADERS)
        if r.status_code != 302:
                return ""
        ref_url2 = r.headers.get("location")
        #fncPrint("ref_url2: " + ref_url2)

        code = extract_code(ref_url2)
        state = extract_state(ref_url2)
        # load ref page
        fncReturnProgress(8, "load ref page")
        r = s.get(ref_url2, headers=AUTHHEADERS)
        if r.status_code != 200:
            return ""

        #get location
        fncReturnProgress(9, "get location")
        AUTHHEADERS["Faces-Request"] = ""
        AUTHHEADERS["Referer"] = ref_url2
        post_data = {
                '_33_WAR_cored5portlet_code': code,
                '_33_WAR_cored5portlet_landingPageUrl': ''
        }
        r = s.post(base + urlsplit(ref_url2).path + '?p_auth=' + state + '&p_p_id=33_WAR_cored5portlet&p_p_lifecycle=1&p_p_state=normal&p_p_mode=view&p_p_col_id=column-1&p_p_col_count=1&_33_WAR_cored5portlet_javax.portlet.action=getLoginStatus', data=post_data, allow_redirects=False, headers=AUTHHEADERS)
        if r.status_code != 302:
            return ""

        #load second ref page
        fncReturnProgress(10, "load second ref page")
        ref_url3 = r.headers.get("location")
        #fncPrint("ref_url3: " + ref_url3)
        r = s.get(ref_url3, headers=AUTHHEADERS)
        #We have a new CSRF
        csrf = extract_csrf(r)               
        # done!!!! we are in at last
        # Update headers for requests
        HEADERS["Referer"] = ref_url3
        HEADERS["X-CSRF-Token"] = csrf

        fncReturnProgress(0, "")

        return ref_url3


def CarNetPost(s,url_base,command):
        fncPrint(command)
        r = s.post(url_base + command, headers=HEADERS)
        return r.content

def CarNetPostAction(s,url_base,command,data):
        fncPrint(command)
        r = s.post(url_base + command, json=data, headers=HEADERS)
        return r.content

def retrieveCarNetInfo(s,url_base):
        fncReturnJSON(CarNetPost(s,url_base, '/-/msgc/get-new-messages'), 'get-new-messages')
        #fncReturnJSON(CarNetPost(s,url_base, '/-/vsr/request-vsr'), 'request-vsr')
        fncReturnJSON(CarNetPost(s,url_base, '/-/vsr/get-vsr'), 'get-vsr')
        fncReturnJSON(CarNetPost(s,url_base, '/-/cf/get-location'), 'get-location')
        fncReturnJSON(CarNetPost(s,url_base, '/-/vehicle-info/get-vehicle-details'), 'get-vehicle-details')
        fncReturnJSON(CarNetPost(s,url_base, '/-/emanager/get-emanager'), 'get-emanager')
        fncReturnJSON(CarNetPost(s,url_base, '/-/mainnavigation/get-fully-loaded-cars'), 'get-fully-loaded-cars')
        fncReturnJSON(CarNetPost(s,url_base, '/-/rts/get-last-refuel-trip-statistics'), 'get-last-refuel-trip-statistics')
        return 0

def startCharge(s,url_base):
        post_data = {
                'triggerAction': True,
                'batteryPercent': '100'
        }
        fncPrint(CarNetPostAction(s,url_base, '/-/emanager/charge-battery', post_data))
        return 0

def stopCharge(s,url_base):
        post_data = {
                'triggerAction': False,
                'batteryPercent': '99'
        }
        fncPrint(CarNetPostAction(s,url_base, '/-/emanager/charge-battery', post_data))
        return 0

def startClimat(s,url_base):
        post_data = {
                'triggerAction': True,
                'electricClima': True
        }
        fncPrint(CarNetPostAction(s,url_base, '/-/emanager/trigger-climatisation', post_data))
        return 0

def stopClimat(s,url_base):
        post_data = {
                'triggerAction': False,
                'electricClima': True
        }
        fncPrint(CarNetPostAction(s,url_base, '/-/emanager/trigger-climatisation', post_data))
        return 0

def startWindowMelt(s,url_base):
        post_data = {
                'triggerAction': True
        }
        fncPrint(CarNetPostAction(s,url_base, '/-/emanager/trigger-windowheating', post_data))
        return 0

def stopWindowMelt(s,url_base):
        post_data = {
                'triggerAction': False
        }
        fncPrint(CarNetPostAction(s,url_base, '/-/emanager/trigger-windowheating', post_data))
        return 0

def getCarDataUpdate(s,url_base):
        fncReturnJSON(CarNetPost(s,url_base, '/-/vsr/request-vsr'), 'request-vsr')
        return 0


def fncCarNet(sCommand, sUsername, sPassword):
    CARNET_USERNAME = sUsername
    CARNET_PASSWORD = sPassword

    s = requests.Session()
    url = CarNetLogin(s,CARNET_USERNAME,CARNET_PASSWORD)
    if url == '':
        fncPrint("Failed to login")
        return 0

    if(sCommand == "retrieveCarNetInfo"):
        retrieveCarNetInfo(s,url)
    elif(sCommand == "getCarDataUpdate"):
        getCarDataUpdate(s,url)
    else:
        if(sCommand == "startCharge"):
            startCharge(s,url)
        elif(sCommand == "stopCharge"):
            stopCharge(s,url)
        elif(sCommand == "startClimat"):
            startClimat(s,url)
        elif(sCommand == "stopClimat"):
            stopClimat(s,url)
        elif(sCommand == "startWindowMelt"):
            startWindowMelt(s,url)
        elif(sCommand == "stopWindowMelt"):
            stopWindowMelt(s,url)        
        # Below is the flow the web app is using to determine when action really started
        # You should look at the notifications until it returns a status JSON like this
        # {"errorCode":"0","actionNotificationList":[{"actionState":"SUCCEEDED","actionType":"STOP","serviceType":"RBC","errorTitle":null,"errorMessage":null}]}
        fncPrint(CarNetPost(s,url, '/-/msgc/get-new-messages'))
        fncPrint(CarNetPost(s,url, '/-/emanager/get-notifications'))
        fncPrint(CarNetPost(s,url, '/-/msgc/get-new-messages'))
        fncPrint(CarNetPost(s,url, '/-/emanager/get-emanager'))

def fncPrint(sMessageText):
    pyotherside.send('PrintMessageText', sMessageText)

def fncReturnJSON(sJSonData, sCommand):
    pyotherside.send('ReturnJSON', sJSonData, sCommand)

def fncReturnProgress(progressStep, sProgressText):
    pyotherside.send('ReturnProgress', progressStep, sProgressText)
