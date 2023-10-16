<div data-widget-area="header">
    {{{ each widgets.header }}}
    {{ widgets.header.html }}
    {{{ end }}}
</div>
<div class="row login flex-fill">
    <div
        class="d-flex flex-column gap-2 {{{ if widgets.sidebar.length }}}col-lg-9 col-sm-12{{{ else }}}col-lg-12{{{ end }}}">
        <h2 class="tracking-tight fw-semibold text-center">[[passkeys:login-with-passkey]]</h2>
        <div class="row justify-content-center gap-5">
            <div class="col-12 col-md-5 col-lg-3 px-md-0">
                <div class="login-block text-center">
                    <div class="alert alert-danger alert-dismissible" id="login-error-notify" {{{ if error
                        }}}style="display:block" {{{ else }}}style="display: none;" {{{ end }}}>
                        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                        <strong>[[login:failed_login_attempt]]</strong>
                        <p>{error}</p>
                    </div>

                    <button class="btn btn-primary" id="login" data-action="triggerLogin">
                        [[passkeys:login-with-passkey]]
                    </button>
                </div>
            </div>
        </div>
    </div>
    <div data-widget-area="sidebar" class="col-lg-3 col-sm-12 {{{ if !widgets.sidebar.length }}}hidden{{{ end }}}">
        {{{ each widgets.sidebar }}}
        {{ widgets.sidebar.html }}
        {{{ end }}}
    </div>
</div>
<div data-widget-area="footer">
    {{{ each widgets.footer }}}
    {{ widgets.footer.html }}
    {{{ end }}}
</div>