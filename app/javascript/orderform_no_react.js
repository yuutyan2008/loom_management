// ロール数、数量の入力で５桁以上の数字が入力できない、メッセージを表示
// 空のフォームがあれば送信ボタンを押せない

var isCompanyValid = false;
var isProductNumberValid = false;
var isColorNumberValid = false;
var isRollCountValid = false;
var isQuantityValid = false;
var isMachineTypeValid = false;
var isStartDateValid = false;

// フォームタグの取得
var orderForm = document.querySelector("#orderForm");
// console.log(orderForm);

// 各入力フィールドの取得
var companyField = document.querySelector("#order_company_id");
var productNumberField = document.querySelector("#order_product_number_id");
var colorNumberField = document.querySelector("#order_color_number_id");
var rollCountField = document.querySelector("#order_roll_count");
var quantityField = document.querySelector("#order_quantity");
var machineTypeField = document.querySelector("#machine_type_id");
var startDateField = document.querySelector("#start_date_field");

// フォーム送信ボタンの取得
//var submitBtn = document.querySelector("input[type='submit']");
var userSubmitBtn = document.querySelector("input[type='submit']");

// 各フィールドのエラーメッセージ表示用 p 要素を動的に生成
var companyError = document.createElement("p");
var productNumberError = document.createElement("p");
var colorNumberError = document.createElement("p");
var rollCountError = document.createElement("p");
var quantityError = document.createElement("p");
var machineTypeError = document.createElement("p");
var startDateError = document.createElement("p");

// エラーメッセージ用のクラスを設定
companyError.classList.add("text-red-500");
productNumberError.classList.add("text-red-500");
colorNumberError.classList.add("text-red-500");
rollCountError.classList.add("text-red-500");
quantityError.classList.add("text-red-500");
machineTypeError.classList.add("text-red-500");
startDateError.classList.add("text-red-500");

// バリデーション関数とイベントリスナーの設定
companyField.addEventListener("change", validateCompany);
productNumberField.addEventListener("change", validateProductNumber);
colorNumberField.addEventListener("change", validateColorNumber);
rollCountField.addEventListener("input", validateRollCount);
quantityField.addEventListener("input", validateQuantity);
machineTypeField.addEventListener("change", validateMachineType);
startDateField.addEventListener("change", validateStartDate);

// フォーム送信ボタンの有効化/無効化制御
function toggleSubmitButton() {
  if (
    isCompanyValid &&
    isProductNumberValid &&
    isColorNumberValid &&
    isRollCountValid &&
    isQuantityValid &&
    isMachineTypeValid &&
    isStartDateValid
  ) {
    userSubmitBtn.disabled = false;
  } else {
    userSubmitBtn.disabled = true;
  }
}

// 各バリデーション関数
function validateCompany() {
  console.log("validateCompany");
  if (!companyField.value) {
    companyError.textContent = "会社名を選択してください。";
    companyField.parentNode.appendChild(companyError);
    isCompanyValid = false;
  } else {
    companyError.textContent = "";
    isCompanyValid = true;
  }
  toggleSubmitButton();
}

function validateProductNumber() {
  console.log("validateProductNumber");
  if (!productNumberField.value) {
    productNumberError.textContent = "品番を選択してください。";
    productNumberField.parentNode.appendChild(productNumberError);
    isProductNumberValid = false;
  } else {
    productNumberError.textContent = "";
    isProductNumberValid = true;
  }
  toggleSubmitButton();
}

function validateColorNumber() {
  console.log("validateColorNumber");
  if (!colorNumberField.value) {
    colorNumberError.textContent = "色番を選択してください。";
    colorNumberField.parentNode.appendChild(colorNumberError);
    isColorNumberValid = false;
  } else {
    colorNumberError.textContent = "";
    isColorNumberValid = true;
  }
  toggleSubmitButton();
}

function validateRollCount() {
  console.log("validateRollCount");
  if (
    !rollCountField.value ||
    rollCountField.value <= 0 ||
    rollCountField.value.length > 4
  ) {
    rollCountError.textContent = "反数は1以上4桁以下の値を入力してください。";
    rollCountField.parentNode.appendChild(rollCountError);
    isRollCountValid = false;
  } else {
    rollCountError.textContent = "";
    isRollCountValid = true;
  }
  toggleSubmitButton();
}

function validateQuantity() {
  console.log("validateQuantity");
  if (
    !quantityField.value ||
    quantityField.value <= 0 ||
    quantityField.value.length > 4
  ) {
    quantityError.textContent = "数量は1以上4桁以下の値を入力してください。";
    quantityField.parentNode.appendChild(quantityError);
    isQuantityValid = false;
  } else {
    quantityError.textContent = "";
    isQuantityValid = true;
  }
  toggleSubmitButton();
}

function validateMachineType() {
  console.log("validateMachineType");
  if (!machineTypeField.value) {
    machineTypeError.textContent = "機械のタイプを選択してください。";
    machineTypeField.parentNode.appendChild(machineTypeError);
    isMachineTypeValid = false;
  } else {
    machineTypeError.textContent = "";
    isMachineTypeValid = true;
  }
  toggleSubmitButton();
}

function validateStartDate() {
  console.log("validateStartDate");
  if (!startDateField.value) {
    startDateError.textContent = "作業開始日を選択してください。";
    startDateField.parentNode.appendChild(startDateError);
    isStartDateValid = false;
  } else {
    startDateError.textContent = "";
    isStartDateValid = true;
  }
  toggleSubmitButton();
}
