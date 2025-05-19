#!/usr/bin/env python3
# RISC-V Multicore CPU Test Runner
# Automated test suite executor for the RISC-V CPU project

import os
import sys
import argparse
import subprocess
import time
from datetime import datetime

# Define test categories
TEST_CATEGORIES = {
    "unit": "Unit tests for individual components",
    "integration": "Integration tests for combined components",
    "functional": "Functional tests for full system verification",
    "regression": "Regression tests to prevent regressions"
}

# Colors for terminal output
class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def print_header(msg):
    """Print a formatted header message"""
    print(f"\n{Colors.BOLD}{Colors.HEADER}===== {msg} ====={Colors.ENDC}\n")

def print_result(name, result, time_taken):
    """Print test result with appropriate coloring"""
    if result:
        status = f"{Colors.OKGREEN}PASS{Colors.ENDC}"
    else:
        status = f"{Colors.FAIL}FAIL{Colors.ENDC}"
    print(f"{name:.<40} {status} ({time_taken:.2f}s)")

def run_test(test_path):
    """Run a single test and return result"""
    start_time = time.time()
    
    # Extract test name from path
    test_name = os.path.basename(test_path).replace('.sv', '')
    
    # Determine test type based on directory
    if 'unit' in test_path:
        print(f"Running unit test: {test_name}")
        cmd = f"cd $(git rev-parse --show-toplevel) && make unit_test TEST={test_name}"
    elif 'integration' in test_path:
        print(f"Running integration test: {test_name}")
        cmd = f"cd $(git rev-parse --show-toplevel) && make integration_test TEST={test_name}"
    elif 'functional' in test_path:
        print(f"Running functional test: {test_name}")
        cmd = f"cd $(git rev-parse --show-toplevel) && make functional_test TEST={test_name}"
    elif 'regression' in test_path:
        print(f"Running regression test: {test_name}")
        cmd = f"cd $(git rev-parse --show-toplevel) && make regression_test TEST={test_name}"
    else:
        print(f"Running test: {test_name}")
        cmd = f"cd $(git rev-parse --show-toplevel) && make test TEST={test_name}"
    
    # Run the test command
    result = subprocess.run(cmd, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
    
    # Calculate time taken
    time_taken = time.time() - start_time
    
    # Check result
    success = result.returncode == 0
    
    # Print result
    print_result(test_name, success, time_taken)
    
    if not success:
        print(f"\n{Colors.FAIL}Error output:{Colors.ENDC}")
        print(result.stderr.decode('utf-8'))
    
    return success, time_taken

def discover_tests(category=None):
    """Discover all test files in the testsuite directory"""
    base_dir = os.path.dirname(os.path.abspath(__file__))
    testsuite_dir = os.path.join(base_dir, "testsuite")
    
    tests = []
    
    if category:
        # Only discover tests in the specified category
        category_dir = os.path.join(testsuite_dir, category)
        if os.path.exists(category_dir):
            for filename in os.listdir(category_dir):
                if filename.endswith('.sv'):
                    tests.append(os.path.join(category_dir, filename))
    else:
        # Discover all tests
        for root, _, files in os.walk(testsuite_dir):
            for filename in files:
                if filename.endswith('.sv'):
                    tests.append(os.path.join(root, filename))
    
    return sorted(tests)

def main():
    """Main test runner function"""
    parser = argparse.ArgumentParser(description="RISC-V CPU Test Runner")
    parser.add_argument('--category', choices=TEST_CATEGORIES.keys(), 
                        help='Run tests only from this category')
    parser.add_argument('--test', help='Run a specific test file')
    parser.add_argument('--list', action='store_true', help='List available tests')
    args = parser.parse_args()
    
    # Print header
    print_header("RISC-V Multicore CPU Test Runner")
    
    # List tests if requested
    if args.list:
        print("Available tests:")
        for category in TEST_CATEGORIES:
            print(f"\n{Colors.BOLD}{category}{Colors.ENDC}: {TEST_CATEGORIES[category]}")
            tests = discover_tests(category)
            for test in tests:
                print(f"  - {os.path.basename(test)}")
        return 0
    
    # Run a specific test if provided
    if args.test:
        if os.path.exists(args.test):
            test_path = args.test
        else:
            # Try to find the test in testsuite directory
            found = False
            for root, _, files in os.walk(os.path.join(os.path.dirname(os.path.abspath(__file__)), "testsuite")):
                if args.test in files or f"{args.test}.sv" in files:
                    test_file = args.test if args.test in files else f"{args.test}.sv"
                    test_path = os.path.join(root, test_file)
                    found = True
                    break
            
            if not found:
                print(f"{Colors.FAIL}Error: Test '{args.test}' not found{Colors.ENDC}")
                return 1
        
        success, _ = run_test(test_path)
        return 0 if success else 1
    
    # Run tests by category or all tests
    tests = discover_tests(args.category)
    
    if not tests:
        print(f"{Colors.WARNING}No tests found{Colors.ENDC}")
        return 0
    
    print(f"Running {len(tests)} tests...")
    
    # Track statistics
    passed = 0
    failed = 0
    total_time = 0
    
    # Run each test
    for test in tests:
        success, time_taken = run_test(test)
        if success:
            passed += 1
        else:
            failed += 1
        total_time += time_taken
    
    # Print summary
    print_header("Test Summary")
    print(f"Total tests: {len(tests)}")
    print(f"Passed: {Colors.OKGREEN}{passed}{Colors.ENDC}")
    print(f"Failed: {Colors.FAIL if failed else ''}{failed}{Colors.ENDC}")
    print(f"Time: {total_time:.2f}s")
    
    return 0 if failed == 0 else 1

if __name__ == "__main__":
    sys.exit(main()) 