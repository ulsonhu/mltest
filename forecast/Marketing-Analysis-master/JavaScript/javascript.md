
## minMax

```javascript
function minMax(arr){
  return [Math.min(...arr),Math.max(...arr)];
}
```


## Binary Addition
[stockflow](https://stackoverflow.com/questions/9939760/how-do-i-convert-an-integer-to-binary-in-javascript)
```javascript
function dec2bin(dec){
    return (dec >>> 0).toString(2);
}

dec2bin(1);    // 1
dec2bin(-1);   // 11111111111111111111111111111111
dec2bin(256);  // 100000000
dec2bin(-256); // 11111111111111111111111100000000

// or // 

function addBinary(a,b){
  return (a+b).toString(2)
}
```

in reverse
```javascript
const binaryArrayToNumber = arr => {
  return parseInt(arr.toString().replace(/,/g,''), 2 );
};

const binaryArrayToNumber = arr => parseInt(arr.join(''), 2);

```


## Sum of two lowest positive integers
[JavaScript Array sort() Method](https://www.w3schools.com/jsref/jsref_sort.asp)
```javascript
function sumTwoSmallestNumbers(numbers) {  
  numbers.sort(function(a, b){return a-b});
  return numbers[0] + numbers[1]
  };

//////////////////////////////////////////////////////
var min = function(list){
  list.sort(function(a, b){return a-b});
  return list[0]}
var max = function(list){
  list.sort(function(a, b){return a-b});
  return list[list.length-1] }  

const min = (list) => Math.min(...list);
const max = (list) => Math.max(...list);
```

## Categorize 

```javascript
function openOrSenior(data){
  function determineMembership(member){
    return (member[0] >= 55 && member[1] > 7) ? 'Senior' : 'Open';
  }
  return data.map(determineMembership);
}

function openOrSenior(data){
  var result = [];
  data.forEach(function(member) {
    if(member[0] >= 55 && member[1] > 7) {
      result.push('Senior');
    } else {
      result.push('Open');
    }
  })
  return result;
}
```

## even not moving, but only odd
```javascript 
function sortArray(array) {
  const odd = array.filter((x) => x % 2).sort((a,b) => a - b);
  return array.map((x) => x % 2 ? odd.shift() : x);
}
```

## Consecutive strings
```javascript 
function longestConsec(strarr, k) {
    var longest = "";
    for(var i=0;k>0 && i<=strarr.length-k;i++){
      var tempArray = strarr.slice(i,i+k);
      var tempStr = tempArray.join("");
      if(tempStr.length > longest.length){
        longest = tempStr;
      }
    }
    return longest;
}
```


