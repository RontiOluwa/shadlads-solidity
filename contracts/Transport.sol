// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/Counters.sol";

contract Transport {
    using Counters for Counters.Counter;

    Counters.Counter private _serviceWorkerCount; //total number of Services
    Counters.Counter private _carCount; //total number of Cars
    Counters.Counter private _inspectionCount; //total number of Inspection

    address owner;
    // Cars public cars;

    struct Cars {
        uint256 itemId;
        uint256 VIN;
        string name;
        string color;
    }

    struct Inspection {
        uint256 itemId;
        uint256 VIN;
        string date;
    }

    event CarsItem(uint256 itemId, uint256 VIN, string name, string color);

    event InspectionItem(uint256 _itemId, uint256 VIN, string date);

    mapping(address => uint256) public serviceWorker;
    mapping(uint256 => Cars) public cars;
    mapping(uint256 => Inspection) public inspection;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyServiceWorker() {
        require(serviceWorker[msg.sender] != 0, "No such User");
        _;
    }

    function addWorker(address _addr) public onlyOwner {
        _serviceWorkerCount.increment(); //add 1 to the total number of items ever created
        uint256 itemId = _serviceWorkerCount.current();
        serviceWorker[_addr] = itemId;
    }

    function addCar(
        uint256 _VIN,
        string memory _name,
        string memory _color
    ) public onlyServiceWorker {
        _carCount.increment(); //add 1 to the total number of items ever created
        uint256 itemId = _carCount.current();

        cars[itemId] = Cars(itemId, _VIN, _name, _color);

        emit CarsItem(itemId, _VIN, _name, _color);
    }

    function addInspection(uint256 _VIN, string memory _date)
        public
        onlyServiceWorker
    {
        _inspectionCount.increment(); //add 1 to the total number of items ever created
        uint256 itemId = _inspectionCount.current();

        inspection[itemId] = Inspection(itemId, _VIN, _date);

        emit InspectionItem(itemId, _VIN, _date);
    }

    function getAllCars() public view returns (Cars[] memory) {
        uint256 count = _carCount.current();
        uint256 index = 0;

        Cars[] memory items = new Cars[](count);

        for (uint256 i = 0; i < count; i++) {
            uint256 currentId = cars[i + 1].itemId;
            Cars storage currentItem = cars[currentId];
            items[index] = currentItem;
            index += 1;
        }
        return items;
    }

    function getCar(uint256 vin) public view returns (Cars[] memory) {
        uint256 count = _carCount.current();
        uint256 index = 0;

        Cars[] memory items = new Cars[](count);

        for (uint256 i = 0; i < count; i++) {
            if (cars[i + 1].VIN == vin) {
                uint256 currentId = cars[i + 1].itemId;
                Cars storage currentItem = cars[currentId];
                items[index] = currentItem;
                index += 1;
            }
        }
        return items;
    }

    function getAllInspection() public view returns (Inspection[] memory) {
        uint256 count = _inspectionCount.current();
        uint256 index = 0;

        Inspection[] memory items = new Inspection[](count);

        for (uint256 i = 0; i < count; i++) {
            uint256 currentId = inspection[i + 1].itemId;
            Inspection storage currentItem = inspection[currentId];
            items[index] = currentItem;
            index += 1;
        }
        return items;
    }

    function getServiceWorkerCount() public view returns (uint256) {
        uint256 count = _serviceWorkerCount.current();
        return count;
    }
}
