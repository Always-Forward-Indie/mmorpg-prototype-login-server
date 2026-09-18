// Unit tests for login ThreadPool (void tasks only in this API).
#include "utils/ThreadPool.hpp"

#include <atomic>
#include <chrono>
#include <gtest/gtest.h>
#include <stdexcept>
#include <thread>

TEST(ThreadPool, RunsVoidTasks)
{
    ThreadPool pool(2);
    std::atomic<int> counter{0};
    for (int i = 0; i < 20; ++i)
        pool.enqueueTask([&] { ++counter; });
    for (int i = 0; i < 200 && counter.load() < 20; ++i)
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
    EXPECT_EQ(counter.load(), 20);
}

TEST(ThreadPool, DestructorDrainsQueue)
{
    std::atomic<int> counter{0};
    {
        ThreadPool pool(2);
        for (int i = 0; i < 10; ++i)
            pool.enqueueTask([&] { ++counter; });
    } // join here: all tasks must have run
    EXPECT_EQ(counter.load(), 10);
}

TEST(ThreadPool, ThrowingTaskDoesNotKillWorker)
{
    // Wave 1.8: an uncaught task exception used to propagate out of the worker
    // thread (std::terminate) or silently shrink the pool. Now the worker
    // logs to stderr and keeps serving.
    ThreadPool pool(2);
    pool.enqueueTask([] { throw std::runtime_error("boom"); });
    pool.enqueueTask([] { throw 42; });
    std::atomic<int> counter{0};
    for (int i = 0; i < 20; ++i)
        pool.enqueueTask([&] { ++counter; });
    for (int i = 0; i < 200 && counter.load() < 20; ++i)
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
    EXPECT_EQ(counter.load(), 20);
}
