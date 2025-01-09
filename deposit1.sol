// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

library BokkyPooBahsDateTimeLibrary {
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   https://aa.usno.navy.mil/faq/JD_formula.html
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
    function convertToVietnamTime(uint timestamp) internal pure returns (uint vietnamTimestamp) {
    int offset = 7 * int(SECONDS_PER_HOUR); // UTC+7
    vietnamTimestamp = uint(int(timestamp) + offset);
}

function convertFromVietnamTime(uint vietnamTimestamp) internal pure returns (uint timestamp) {
    int offset = 7 * int(SECONDS_PER_HOUR); // UTC+7
    timestamp = uint(int(vietnamTimestamp) - offset);
}}

/////////////////////////////////////CONNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
    ////////////////////////////////// TRACTTTTTTTTTTTTTTTTTTT


contract DepositSaving {
    using BokkyPooBahsDateTimeLibrary for uint;

    // Lãi suất cố định
     uint public BaseinterestRate = 1;  // 1% lãi suất không kỳ hạn
     string public OptineTime="co 3 ky han: 3,6,9,12";
     address public owner;
    // cấu trúc khoản gửi
    struct Deposit {
        uint amount;        
        uint startTime;     
        uint optionTime;    
        uint interestRate;
    }
    constructor (){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require( msg.sender == owner, "only the owner have the permission to operate");_;
    }

    mapping(address => Deposit[]) private   deposits;
    
    event Deposited(address indexed user, uint amount, uint optionsTime, uint interestRate, uint startTime);
    event Withdrawn( uint Raw_amount, uint optionsTime, uint interest, uint totalAmount, uint startTime, uint TimeExprised);
    event Reinvested ( uint new_amount, uint OptineTime, uint interestRate, uint startTime );

    // Hàm gửi tiền 
    function deposit(uint amount, uint optionTime) public   onlyOwner {
        require(amount >= 10000000, "so tien gui phai lon hon 10 000 000");
        require(optionTime == 2 || optionTime == 6 || optionTime == 9 || optionTime == 12, "OptionTime no valid");

        uint interestRate;
        if (amount <= 100000000) {
            if (optionTime == 2) interestRate = 10;
            else if (optionTime == 6) interestRate = 15;
            else if (optionTime == 9) interestRate = 20;
            else interestRate = 25;
        } else if (amount > 100000000 && amount <= 500000000) {
            if (optionTime == 2) interestRate = 15;
            else if (optionTime == 6) interestRate = 20;
            else if (optionTime == 9) interestRate = 25;
            else interestRate = 30;
        } else {
            if (optionTime == 2) interestRate = 20;
            else if (optionTime == 6) interestRate = 25;
            else if (optionTime == 9) interestRate = 30;
            else interestRate = 35;
        }

        // Ghi nhận khoản gửi của người dùng
        deposits[msg.sender].push(Deposit({
            amount: amount,
            startTime: block.timestamp,
            optionTime: optionTime,
            interestRate: interestRate
          }));

        emit Deposited(msg.sender, amount, optionTime, interestRate, block.timestamp);
    }

 function withdraw( uint depositIndex) public  onlyOwner noActiveLoans returns (uint, string memory) {
    Deposit memory userDeposit = deposits[msg.sender][depositIndex];
    require(userDeposit.amount > 0, "No deposit found");

    // Tính thời gian 
    uint timeDeposited = (block.timestamp - userDeposit.startTime) ;
    uint requireTime = userDeposit.optionTime * 60; 

    uint interestRate;

    // Tính lãi suất
    if (timeDeposited < requireTime) {
        interestRate = BaseinterestRate;
    } else {
        interestRate = userDeposit.interestRate;
    }

    // Tính lãi suất và tổng tiền
    uint totalInterest = (userDeposit.amount * interestRate / 100 * timeDeposited) / 3600; // Tính theo ngày
    uint totalAmount = userDeposit.amount + totalInterest;

    // Kiểm tra nếu đã đến hạn nhưng chưa rút => tái hợp đồng 
    if (timeDeposited >= (requireTime + requireTime * 25 / 100)) {
        // Cập nhật khoản gửi mới
        deposits[msg.sender][depositIndex] = Deposit({
            amount: totalAmount,
            startTime: block.timestamp,
            optionTime: userDeposit.optionTime,
            interestRate: userDeposit.interestRate
        });

        // Tạo thông báo
        string memory message = "Your deposit has been reinvested. Check your updated deposit details.";

        // Emit sự kiện tái hợp đồng
        emit Reinvested( totalAmount, userDeposit.optionTime, userDeposit.interestRate, block.timestamp);

        // Trả về số tiền tái hợp đồng và thông báo
        return (totalAmount, message);
    }

    // Nếu người dùng muốn rút đúng hạn
    delete deposits[msg.sender][depositIndex];

    emit Withdrawn(
        userDeposit.amount,
        userDeposit.optionTime,
        totalInterest,
        totalAmount,
        userDeposit.startTime,
        block.timestamp
    );

    // Trả về số tiền đã rút và thông báo
    return (totalAmount, "You have successfully withdrawn your deposit fund.");
}
//////////////////// Hàm tính ngày hết hạn, kèm theo giờ, phút, giây

    event Calculate_Expired( address  user, uint Deposit_index, uint year, uint month, uint day, uint hour,uint minute, uint second );
    event CalculateS_tartTime( address  user, uint Deposit_index, uint year, uint month, uint day, uint hour,uint minute, uint second );

function CalculateStartTime(uint depositIndex) 
    public  
    returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
    require(depositIndex < deposits[msg.sender].length, "Invalid deposit index");
    
    Deposit memory userDeposit = deposits[msg.sender][depositIndex];
    uint starttime = BokkyPooBahsDateTimeLibrary.convertToVietnamTime(userDeposit.startTime); // Chuyển sang giờ Việt Nam

    (year, month, day, hour, minute, second) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(starttime);
    emit CalculateS_tartTime(msg.sender, depositIndex, year, month, day, hour, minute, second);
}


function CalculateExpired(uint depositIndex) 
    public   
    returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
    require(depositIndex < deposits[msg.sender].length, "Invalid deposit index");
    
    Deposit memory userDeposit = deposits[msg.sender][depositIndex];
    uint maturity_Date = userDeposit.startTime + (userDeposit.optionTime * 60);
    maturity_Date = BokkyPooBahsDateTimeLibrary.convertToVietnamTime(maturity_Date); // Chuyển sang giờ Việt Nam

    (year, month, day, hour, minute, second) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(maturity_Date);
    emit Calculate_Expired(msg.sender, depositIndex, year, month, day, hour, minute, second);
}

    /// hàm kiểm tra thông tin
function get_IndexDeposits() public  view returns (
    uint[] memory amounts,
    uint[] memory startTimes,
    uint[] memory optionTimes,
    uint[] memory interestRates
) {
    Deposit[] memory userDeposits = deposits[msg.sender];
    uint depositCount = userDeposits.length;

    amounts = new uint[](depositCount);
    startTimes = new uint[](depositCount);
    optionTimes = new uint[](depositCount);
    interestRates = new uint[](depositCount);

    for (uint i = 0; i < depositCount; i++) {
        Deposit memory dep = userDeposits[i];
        amounts[i] = dep.amount;
        startTimes[i] = dep.startTime;
        optionTimes[i] = dep.optionTime;
        interestRates[i] = dep.interestRate;
    }
}


///////////////////////// LOAN /////////////////////////////////////////////////////////////////////
    struct Loan {
        uint loanAmount;    // Số tiền vay
        uint interestRate;  // Lãi suất vay
        uint startTime;     // Thời gian bắt đầu vay
        uint duration;      // Thời hạn vay (tháng)
        uint remainingRepayment;   // Số tiền còn lại phải trả (gồm cả gốc và lãi)
        uint total_Repayment;      // Tổng số tiền phải trả ban đầu
    }

    mapping(address => Loan[]) private loans;
    mapping(address => uint[]) private userOptionsDuration;


    event LoanTaken(address indexed user, uint loanAmount, uint interestRate, uint startTime, uint duration, uint debt_Amount_mustRePaid);
    event LoanRepaid(address indexed user, uint repaymentAmount, uint loan_amount_remaining);
    event ValidityChecked(uint maxLoanAmount, uint remainingMonths,uint[] options_duration,string  interest_rate_borrow);

    modifier noActiveLoans() {
    for (uint i = 0; i < loans[msg.sender].length; i++) {
        if (loans[msg.sender][i].remainingRepayment > 0) {
            revert("You must repay all active loans before withdrawing deposits.");
        }}_;}


    modifier hasDeposit(uint depositIndex ) {
        require(deposits[msg.sender][depositIndex].amount > 0, "No deposit found");
        _;
    }
/////////////////////////////
function calculate_and_checkValidity( uint depositIndex)
    public 
    onlyOwner   
    returns (
        uint maxLoanAmount,
        uint remainingMonths,
        uint[] memory options_duration,
        string  memory interest_rate_borrow
    ) {
    Deposit memory userDeposit = deposits[msg.sender][depositIndex];

    uint maturityDate = userDeposit.startTime + (userDeposit.optionTime * 30 days);
    require(maturityDate > block.timestamp, "Deposit fund has been withdrawn");
    remainingMonths = (maturityDate - block.timestamp) / 30 days;

    options_duration = new uint[](remainingMonths);
    for (uint i = 0; i < remainingMonths; i++) {
        options_duration[i] = i + 1;
    }

    userOptionsDuration[msg.sender] = options_duration; // Lưu lại danh sách này

    maxLoanAmount = userDeposit.amount * 80 / 100;
    interest_rate_borrow = "if you borrow an amount that exceeds 50% of the maxloanAmount, the interest_borrow is 2 % , otherwise it is 3%";
    emit ValidityChecked( maxLoanAmount, remainingMonths, options_duration, interest_rate_borrow);

    return (maxLoanAmount, remainingMonths, options_duration, interest_rate_borrow);
}

    function isValidDuration(uint[] memory options_duration, uint duration) internal pure returns (bool) {
        for (uint i = 0; i < options_duration.length; i++) {
            if (options_duration[i] == duration) {
                return true;
            }
        }
        return false;
    }
///////////////////////////////
    /////////increase protection
    mapping(address => mapping(uint => bool)) private hasBorrowed;
function borrow(uint depositIndex, uint loanAmount, uint _duration) public hasDeposit(depositIndex) {

    // Kiểm tra xem depositIndex này đã được vay chưa
    require(!hasBorrowed[msg.sender][depositIndex], "This deposit has already been used for a loan");

    Deposit memory userDeposit = deposits[msg.sender][depositIndex];
    uint interest_rate_borrow;

    // Ensure the loan amount doesn't exceed 80% of the deposit
    uint maxLoanAmount = userDeposit.amount * 80 / 100;
    require(loanAmount <= maxLoanAmount, "Loan amount exceeds 80% of deposit");

    // Tính lãi suất
    if (loanAmount <= (50 * maxLoanAmount) / 100) {
        interest_rate_borrow = (userDeposit.interestRate + 20); // 2% lãi suất
    } else {
        interest_rate_borrow = (userDeposit.interestRate + 30); // 3% lãi suất
    }

    uint totalRepayment = loanAmount + (loanAmount * interest_rate_borrow / 100 * _duration / 12);

    // Ensure duration is valid
    uint[] memory options_duration = userOptionsDuration[msg.sender];
    require(isValidDuration(options_duration, _duration), "Invalid duration");

    // Check if user already has an active loan

    // Thêm khoản vay vào mảng
    loans[msg.sender].push(Loan({
        loanAmount: loanAmount,
        interestRate: interest_rate_borrow,
        startTime: block.timestamp,
        duration: _duration,
        remainingRepayment: totalRepayment,
        total_Repayment: totalRepayment

    }));
    // Đánh dấu depositIndex đã được sử dụng để vay
    hasBorrowed[msg.sender][depositIndex] = true;
    emit LoanTaken(msg.sender, loanAmount, interest_rate_borrow, block.timestamp, _duration, totalRepayment );}


function repayLoan(uint loanIndex, uint repaymentAmount) public onlyOwner {

    Loan storage userLoan = loans[msg.sender][loanIndex];

    require(repaymentAmount <= userLoan.total_Repayment, "Incorrect repayment amount. Please pay the correct amount.");

    // Giảm số dư khoản vay
    userLoan.remainingRepayment -= repaymentAmount;

    // Phát sự kiện khi trả nợ thành công
    emit LoanRepaid(msg.sender, repaymentAmount, userLoan.remainingRepayment);

    // Nếu khoản vay đã trả hết
    if (userLoan.remainingRepayment == 0) {
        delete loans[msg.sender][loanIndex];
    }
}


///////////////////////////////////////
function get_IndexLoans() 
    public  
    view 
    returns (
        uint[] memory loanAmounts,
        uint[] memory interestRates,
        uint[] memory startTimes,
        uint[] memory durations
    ) 
{
    // Lấy danh sách tất cả các khoản vay của người dùng
    Loan[] memory userLoans = loans[msg.sender];
    uint loanCount = userLoans.length;

    // Khởi tạo các mảng để lưu thông tin khoản vay
    loanAmounts = new uint[](loanCount);
    interestRates = new uint[](loanCount);
    startTimes = new uint[](loanCount);
    durations = new uint[](loanCount);

    // Lặp qua tất cả các khoản vay và lưu thông tin vào các mảng tương ứng
    for (uint i = 0; i < loanCount; i++) {
        Loan memory loan = userLoans[i];
        loanAmounts[i] = loan.loanAmount;
        interestRates[i] = loan.interestRate;
        startTimes[i] = loan.startTime;
        durations[i] = loan.duration;
    }
}

}

