#pragma once
// S17a: login version-attempt distribution ("who knocks").
// Pure + thread-safe, no sockets/DB/config so unit tests can pin it
// directly. NetworkManager records EVERY authentificationClient /
// registerAccount attempt (accepted AND rejected — the point is seeing
// stale and foreign clients, not just the healthy ones).
// DoS guard: keys truncated to 32 chars, at most kMaxDistinct distinct
// keys, overflow goes to the "_other" bucket (garbage versions must not
// grow memory unbounded).
#include <algorithm>
#include <cstdint>
#include <mutex>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

class VersionStats
{
public:
    static constexpr size_t kMaxKeyLen = 32;
    static constexpr size_t kMaxDistinct = 64;
    static constexpr const char *kOtherBucket = "_other";
    static constexpr const char *kEmptyBucket = "(empty)";

    void record(const std::string &version)
    {
        std::string key = version.substr(0, kMaxKeyLen);
        if (key.empty())
            key = kEmptyBucket;
        std::lock_guard<std::mutex> lock(mutex_);
        auto it = counts_.find(key);
        if (it == counts_.end())
        {
            if (counts_.size() >= kMaxDistinct)
                ++counts_[kOtherBucket];
            else
                ++counts_[key];
        }
        else
        {
            ++it->second;
        }
        ++total_;
    }

    /// "0.2.0=5 0.1.2=2 (n=7)" sorted by count desc. Empty when nothing
    /// recorded (callers skip logging an empty line).
    std::string snapshot() const
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (counts_.empty())
            return "";
        std::vector<std::pair<std::string, uint64_t>> rows(counts_.begin(), counts_.end());
        std::sort(rows.begin(), rows.end(),
            [](const auto &a, const auto &b) { return a.second > b.second; });
        std::string out;
        for (const auto &row : rows)
        {
            if (!out.empty())
                out += " ";
            out += row.first + "=" + std::to_string(row.second);
        }
        out += " (n=" + std::to_string(total_) + ")";
        return out;
    }

    uint64_t total() const
    {
        std::lock_guard<std::mutex> lock(mutex_);
        return total_;
    }

    void clear()
    {
        std::lock_guard<std::mutex> lock(mutex_);
        counts_.clear();
        total_ = 0;
    }

private:
    mutable std::mutex mutex_;
    std::unordered_map<std::string, uint64_t> counts_;
    uint64_t total_{0};
};
