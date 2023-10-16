<!-- IMPORT partials/account/header.tpl -->

<div class="row">
	<div class="col-12 col-sm-8 offset-sm-2">
		{{{ if !hasPasskey }}}
			<p class="lead">
				[[passkeys:user.intro.one]]
			</p>
			<p>
				[[passkeys:user.intro.two]]
			</p>
			<p>
				[[passkeys:user.intro.three]]
			</p>
		{{{ else }}}
			<p class="lead text-center">
				[[passkeys:user.manage.lead]]
			</p>
		{{{ end }}}
	</div>
</div>

<hr />

<div class="row">
	<div class="list-group col-12 col-sm-8 offset-sm-2">
		<div class="list-group-item">
			<div class="pull-right">
				<a role="button" data-action="setupAuthn" class="{{{ if hasPasskey }}}text-muted{{{ end }}}">[[passkeys:user.manage.enable]]</a>
				&nbsp;&nbsp;&nbsp;&nbsp;
				<a role="button" data-action="disableAuthn" class="{{{ if !hasPasskey }}}text-muted{{{ end }}}">[[passkeys:user.manage.disable]]</a>
			</div>
			<div class="clear"></div>
		</div>
	</div>
</div>

<!-- IMPORT partials/account/footer.tpl -->
