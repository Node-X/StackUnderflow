$ ->
  $("#question_tag_list").tagsinput({
    confirmKeys: [32, 13, 188],
    tagClass: "label label-default"
  })

class @Question
  constructor: () ->
    this.$el = $(".question")
    this.$body = this.$el.find(".question-body")
    this.$title = $("#question-title h1")
    this.$tags = this.$el.find(".question-tags")
    this.tagList = this.$tags.data("tags")
    this.$files = this.$el.find(".question-attachments")
    this.$voting = this.$el.find(".voting")
    this.$votes = this.$voting.find(".votes")
    this.$commentBtn = this.$el.find(".show-comment-form")
    this.$commentForm = this.$el.find(".comment-form")
    this.$commentsWrapper = this.$el.find(".comments-wrapper")
    this.$comments = this.$commentsWrapper.find(".comments")
    this.$answers = $(".answers")
    this.$answerForm = $("#new-answer-form")
    this.$answersCounter = $("#answers-counter")
    this.answersCounter = this.$answersCounter.data("counter")
    this.answers = []
    this.comments = []
    this.id = this.$el.data("question-id")

    this.bind()
    this.setAjaxHooks()
    this.subscribeToChannels()

  bind: () ->
    that = this
    this.$commentBtn.click((e) ->
      e.preventDefault()
      that.toggleCommentForm()
    )
    this.$el.on "click", ".edit-question", (e) ->
      e.preventDefault()
      that.edit(HandlebarsTemplates["edit_question"]({id: that.id, body: that.$body.text(), title: that.$title.text(), tag_list: that.tagList}))
      $("#question_tag_list").tagsinput("refresh")

  setAjaxHooks: () ->
    that = this
    this.$el.on "ajax:success", "form.edit_question", (e, data, status, xhr) ->
      that.$body.text(xhr.responseJSON.body)
      that.$tags.replaceWith(HandlebarsTemplates["question_tags"](xhr.responseJSON))
      that.$files.replaceWith(HandlebarsTemplates["question_attachments"](xhr.responseJSON))
      that.$tags = that.$el.find(".question-tags")
      that.$title.text(xhr.responseJSON.title)
      that.tagList = that.$tags.data("tags")

    this.$el.on "ajax:error", "form.edit_question", (e, xhr, status) ->
      that.renderFormErrors(this, xhr.responseJSON)

    this.$answerForm.on "ajax:success", (e, data, status, xhr) ->
      that.addAnswer(xhr.responseJSON)

    this.$answerForm.on "ajax:error", (e, xhr, status) ->
      that.renderFormErrors(this, xhr.responseJSON)

    this.$commentForm.on "ajax:success", (e, data, status, xhr) ->
      that.addComment(xhr.responseJSON)

    this.$commentForm.on "ajax:error", (e, xhr, status) ->
      that.renderFormErrors(this, xhr.responseJSON)

    this.$el.on "ajax:success", "form.edit_comment", (e, data, status, xhr) ->
      $(this).parents(".comment").replaceWith(HandlebarsTemplates["comment"](xhr.responseJSON))

    this.$el.on "ajax:error", "form.edit_comment", (e, xhr, status) ->
      that.renderFormErrors(this, xhr.responseJSON)

    this.$el.on "ajax:success", "a.delete-comment", (e, data, status, xhr) ->
      that.removeComment($(this).parents(".comment").attr("id").split("_")[1])

    this.$answers.on "ajax:success", "a.delete-answer", (e, xhr, status) ->
      that.removeAnswer($(this).data("id"))

    this.$voting.on "ajax:success", "a.vote-up", (e, data, status, xhr) ->
      that.$votes.text(xhr.responseJSON.votes)
      $(this).remove()
      that.$voting.find("a.vote-down").remove()

    this.$voting.on "ajax:success", "a.vote-down", (e, data, status, xhr) ->
      that.$votes.text(xhr.responseJSON.votes)
      $(this).remove()
      that.$voting.find("a.vote-up").remove()

  subscribeToChannels: () ->
    that = this
    PrivatePub.subscribe "/questions/#{this.id}/answers", (data, channel) ->
      if (typeof data.create != 'undefined')
        that.addAnswer($.parseJSON(data.create))
      if (typeof data.destroy != 'undefined')
        that.removeAnswer($.parseJSON(data.destroy))

    PrivatePub.subscribe "/questions/#{this.id}", (data, channel) ->
      if (typeof data.votes != 'undefined')
        that.$votes.text(data.votes)

  edit: (form) ->
    this.$body.html(form)

  setTitle: (title) ->
    this.$title.text(title)

  toggleCommentForm: () ->
    this.$commentForm.slideToggle()


  addComment: (comment) ->
    if (this.$comments.length == 0 || this.$comments.find(".comment").length == 0)
      this.$comments = $("<ul class='comments'></ul>").appendTo(this.$commentsWrapper)
    this.$comments.append(HandlebarsTemplates["comment"](comment))
    this.comments.push(new Comment("comment_#{comment.id}", "questions", this.id))
    this.toggleCommentForm()
    this.clearCommentForm()

  removeComment: (commentId) ->
    this.$comments.find("#comment_#{commentId}").remove()
    if (this.$comments.is(":empty"))
      this.$comments.remove()
    for comment in this.comments
      if comment.id == parseInt(commentId, 10)
        this.comments.splice(this.comments.indexOf(comment), 1)

  editComment: (comment) ->

  renderCommentForm: (form) ->
    this.$commentForm.html(form)

  clearCommentForm: () ->
    this.$commentForm.find("textarea").val("")
    this.$commentForm.find(".alert-danger").remove()
    this.$commentForm.find(".has-error").removeClass("has-error").find(".help-block").remove()

  addAnswer: (answer) ->
    unless this.answerById(answer.id)
      this.$answers.append(HandlebarsTemplates["answer"](answer))
      this.increaseAnswersCounter()
      this.answers.push(new Answer("answer_#{$(answer).attr("id")}"))
      this.answers[this.answers.length-1].comments = []
      this.clearAnswerForm()

  renderFormErrors: (form, response) ->
    this.clearFormErrors(form)
    $form = $(form)
    $form.prepend("<div class='alert alert-danger'>Please review the problems below:</div>")
    for field, error of response
      field = $form.find(".form-control[id$=#{field}]")
      formGroup = field.parents(".form-group").addClass("has-error")
      formGroup.append("<span class='help-block error'>#{error[0]}</a>")

  clearFormErrors: (form) ->
    $form = $(form)
    $form.find(".alert.alert-danger").remove()
    formGroup = $form.find(".has-error")
    formGroup.find(".help-block.error").remove()
    formGroup.removeClass("has-error")

  clearAnswerForm: () ->
    this.$answerForm.find("textarea").val("")
    this.$answerForm.find(".alert-danger").remove()
    this.$answerForm.find(".has-error").removeClass("has-error").find(".help-block").remove()

  removeAnswer: (answerId) ->
    console.log answerId
    if this.answerById(answerId)
      this.$answers.find("#answer_#{answerId}").remove()
      for answer in this.answers
        if answer.id == parseInt(answerId, 10)
          this.answers.splice(this.answers.indexOf(answer), 1)
      this.decreaseAnswersCounter()

  renderAnswerForm: (form) ->
    this.$answerForm.html(form)

  increaseAnswersCounter: () ->
    this.answersCounter++
    this.renderAnswersCounter()

  decreaseAnswersCounter: () ->
    this.answersCounter--
    this.renderAnswersCounter()

  renderAnswersCounter: () ->
    answerText = if (this.answersCounter > 1 || this.answersCounter == 0) then "Answers" else "Answer"
    this.$answersCounter.text(this.answersCounter + " " + answerText)

  answerById: (id) ->
    for answer in this.answers
      return answer if answer.id == id
    return null

  commentById: (id) ->
    for comment in this.comments
      return comment if comment.id == id
    return null
