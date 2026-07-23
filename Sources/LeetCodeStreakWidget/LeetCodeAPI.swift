import Foundation

struct LeetCodeStats {
    let username: String
    let streak: Int
    let totalActiveDays: Int
    let totalSolved: Int
    let easySolved: Int
    let mediumSolved: Int
    let hardSolved: Int
    let submissionCalendar: [Date: Int]
}

enum LeetCodeAPIError: Error, LocalizedError {
    case userNotFound
    case badResponse
    case decodeFailed

    var errorDescription: String? {
        switch self {
        case .userNotFound: return "Username not found"
        case .badResponse: return "Bad response from LeetCode"
        case .decodeFailed: return "Could not parse LeetCode response"
        }
    }
}

final class LeetCodeAPI {
    private let endpoint = URL(string: "https://leetcode.com/graphql")!

    private let query = """
    query userStreakWidget($username: String!) {
      matchedUser(username: $username) {
        username
        submitStats: submitStatsGlobal {
          acSubmissionNum {
            difficulty
            count
          }
        }
        userCalendar {
          streak
          totalActiveDays
          submissionCalendar
        }
      }
    }
    """

    func fetchStats(username: String) async throws -> LeetCodeStats {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://leetcode.com/\(username)/", forHTTPHeaderField: "Referer")

        let body: [String: Any] = [
            "query": query,
            "variables": ["username": username]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw LeetCodeAPIError.badResponse
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let dataDict = json["data"] as? [String: Any]
        else {
            throw LeetCodeAPIError.decodeFailed
        }

        guard let matchedUser = dataDict["matchedUser"] as? [String: Any] else {
            throw LeetCodeAPIError.userNotFound
        }

        let submitStats = matchedUser["submitStats"] as? [String: Any]
        let acList = submitStats?["acSubmissionNum"] as? [[String: Any]] ?? []

        var totalSolved = 0, easy = 0, medium = 0, hard = 0
        for entry in acList {
            guard let difficulty = entry["difficulty"] as? String, let count = entry["count"] as? Int else { continue }
            switch difficulty {
            case "All": totalSolved = count
            case "Easy": easy = count
            case "Medium": medium = count
            case "Hard": hard = count
            default: break
            }
        }

        let userCalendar = matchedUser["userCalendar"] as? [String: Any]
        let streak = userCalendar?["streak"] as? Int ?? 0
        let totalActiveDays = userCalendar?["totalActiveDays"] as? Int ?? 0
        let calendarJSONString = userCalendar?["submissionCalendar"] as? String ?? "{}"

        var calendar: [Date: Int] = [:]
        if let calendarData = calendarJSONString.data(using: .utf8),
           let rawCalendar = try? JSONSerialization.jsonObject(with: calendarData) as? [String: Any] {
            for (key, value) in rawCalendar {
                guard let timestamp = Double(key) else { continue }
                let count = (value as? Int) ?? Int("\(value)") ?? 0
                calendar[Date(timeIntervalSince1970: timestamp)] = count
            }
        }

        return LeetCodeStats(
            username: username,
            streak: streak,
            totalActiveDays: totalActiveDays,
            totalSolved: totalSolved,
            easySolved: easy,
            mediumSolved: medium,
            hardSolved: hard,
            submissionCalendar: calendar
        )
    }
}
