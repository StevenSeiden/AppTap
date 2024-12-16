// AppTap
// Steven Seiden

import Foundation
import Darwin

func shell(_ command: String) -> String {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.launchPath = "/bin/zsh"
    task.standardInput = nil
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!
    
    return output
}

print("""
\u{001B}[2J
\u{001B}[34m    e Y8b                       88P'888'Y88
   d8b Y8b    888 88e  888 88e  P'  888  'Y  ,"Y88b 888 88e
  d888b Y8b   888 888b 888 888b     888     "8" 888 888 888b
 d888888888b  888 888P 888 888P     888     ,ee 888 888 888P
d8888888b Y8b 888 88"  888 88"      888     "88 888 888 88"
              888      888                          888
              888      888                          888

Welcome to AppTap.

\u{001B}[0m
""")

print("Enter a URL: ", terminator: "")
let appURL = readLine()

var id = ""

if let range = appURL!.range(of: "id", options: .backwards, range: nil, locale: nil) {
    id = String(appURL!.suffix(from: range.upperBound))
} else {
    print("\u{001B}[31mError: Bad URL format.\u{001B}[0m")
    exit(0)
}

let itunesURL = "https://itunes.apple.com/lookup?id=" + id

print("Connecting to \(itunesURL).\n")


var contents = ""

do {
    contents = try String(contentsOf: URL(string: itunesURL)!)
} catch {
    print("\u{001B}[31mError: Cannot connect to the App Store.\u{001B}[0m")
}


var bundleID = ""

if let jsonData = contents.data(using: .utf8) {
    do {
        // Parse the JSON data into a dictionary
        if let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
            // Access the value of the "bundleId" key
            if let results = json["results"] as? [[String: Any]], let firstResult = results.first,
                let foundID = firstResult["bundleId"] as? String {
                bundleID = foundID
                   print("Found \u{001B}[35m\(firstResult["trackName"]!)\u{001B}[0m.")
                print("Bundle ID: \u{001B}[1m\(bundleID)\u{001B}[22m\n")
            } else {
                print("\u{001B}[31mError: Cannot get information from the URL provided.\u{001B}[0m")
                exit(0)
            }
        }
    } catch {
        print("\u{001B}[31mError: Cannot parse JSON: \(error.localizedDescription)\u{001B}[0m")
    }
} else {
    print("\u{001B}[31mError: Failed to get app information.\u{001B}[0m")
}


print("Downloading...")

let ipatoolOut = " "

let ipaToolOut = shell("ipatool download --purchase -b "+bundleID+" -o "+bundleID+".ipa")

if String(ipaToolOut).contains("true") {
    print("Successfully downloaded application!")
} else if String(ipaToolOut).contains("failed to open zip reader") {
    print("\u{001B}[31mError: ipatool could not store the application file. The file may already exist.\u{001B}[0m")
    print("Try deleting previous application file? (Y/N): ")
    let delApp = readLine()
    if(delApp == "Y" || delApp == "y"){
        do{
            try FileManager.default.removeItem(atPath: bundleID+".ipa")
            print("Success; Continuing.")
            shell("ipatool download --purchase -b "+bundleID+" -o "+bundleID+".ipa")
        } catch {
            print("\u{001B}[31mError: Failed to delete.\u{001B}[0m")
            exit(0)
        }
    } else {
        exit(0)
    }
} else if String(ipaToolOut).contains("password token is expired") {
    print("\u{001B}[31mError: Credentials expired. Re-login using \u{001B}[0m\u{001B}[107m\u{001B}[30mipatool auth login -e user@example.com -p password\u{001B}[0m\u{001B}[0m")
    exit(0)
} else if String(ipaToolOut).contains("TLS handshake timeout") {
    print("\u{001B}[31mError: Too many failed login attempts.\u{001B}[0m")
    exit(0)
} else {
    print("\u{001B}[31mError: \n"+ipaToolOut+"\u{001B}[0m")
    exit(0)
}


print("Installing...")

print(shell("open "+bundleID+".ipa"))

/*shell("unzip " + bundleID + ".ipa -d out")

let actualAppName = shell("ls out/Payload")

print(actualAppName)

//shell("rm -rf out")



let decrypt = readLine()


let wrappedAppName = shell("cd /Applications/"+actualAppName+"; ls /Wrapper/ | grep *.app")

print(wrappedAppName)
*/

print("\u{001B}[32mDone!\u{001B}[0m")
