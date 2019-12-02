$(() => {
  const $userRegistrationForm = $("#register-form");
  const $userGroupFields      = $userRegistrationForm.find(".user-group-fields");
  const inputSelector         = 'input[name="user[sign_up_as]"]';
  const newsletterSelector    = 'input[type="checkbox"][name="user[newsletter]"]';
  const $newsletterModal      = $("#sign-up-newsletter-modal");
  const $tosCheckbox          = $("#user_tos_agreement");
  const $nextStepButton       = $('.form-step-button[form-step="1"]');
  const $previousStepButton   = $('.form-step-button[form-step="2"]');

  const setGroupFieldsVisibility = (value) => {
    if (value === "user") {
      $userGroupFields.hide();
    } else {
      $userGroupFields.show();
    }
  }

  const checkNewsletter = (check) => {
    $userRegistrationForm.find(newsletterSelector).prop("checked", check);
    $newsletterModal.data("continue", true);
    $newsletterModal.foundation("close");
    $userRegistrationForm.submit();
  }

  setGroupFieldsVisibility($userRegistrationForm.find(`${inputSelector}:checked`).val());

  $userRegistrationForm.on("change", inputSelector, (event) => {
    const value = event.target.value;

    setGroupFieldsVisibility(value);
  });

  $userRegistrationForm.on("submit", (event) => {
    const newsletterChecked = $userRegistrationForm.find(newsletterSelector);
    if (!$newsletterModal.data("continue")) {
      if (!newsletterChecked.prop("checked")) {
        event.preventDefault();
        $newsletterModal.foundation("open");
      }
    }
  });

  $newsletterModal.find(".check-newsletter").on("click", (event) => {
    checkNewsletter($(event.target).data("check"));
  });

  $previousStepButton.on("click", (event) => {
    event.preventDefault();
    $("[form-step]").toggle();
  });

  $nextStepButton.on("click", (event) => {
    const visibleErrors = $("[form-step='1'] .form-error.is-visible").length > 0;
    const tosAccepted = $tosCheckbox.prop("checked");

    event.preventDefault();

    if (!visibleErrors && tosAccepted) {
      $("[form-step]").toggle();
    }
  });
});
