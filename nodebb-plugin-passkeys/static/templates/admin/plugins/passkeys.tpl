<div class="acp-page-container">
	<!-- IMPORT admin/partials/settings/header.tpl -->

	<div class="row m-0">
		<div id="spy-container" class="col-12 px-2 mb-4" tabindex="0">

			<form role="form" class="passkeys-settings clearfix">
				<div class="mb-4">
					<h5 class="fw-bold tracking-tight settings-header">[[passkeys:admin.users.title]]</h5>
					<p>
						[[passkeys:admin.users.text]]
					</p>

					<!-- IF users.length -->
					<ul class="user-list list-group list-group-horizontal">
						<!-- BEGIN users -->
						<li class="list-group-item">
							<a href="{users.config.relative_path}/user/{users.userslug}">
								<!-- IF ../picture -->
								<img class="avatar" component="user/picture" style="--avatar-size: 32px;" src="{../picture}" itemprop="image" />
								<!-- ELSE -->
								<div class="avatar" component="user/picture" style="--avatar-size: 32px; background-color: {../icon:bgColor};">{../icon:text}</div>
								<!-- END -->
								{users.username}
							</a>
						</li>
						<!-- END users -->
					</ul>
					<!-- ELSE -->
					<div class="alert alert-warning text-center">
						<em>[[passkeys:admin.users.none]]</em>
					</div>
					<!-- ENDIF users.length -->
				</div>

				<div class="mb-4">
					<h5 class="fw-bold tracking-tight settings-header">[[passkeys:admin.force_2fa]]</h5>
					<div class="mb-3">
						<div class="form-group">
							<label for="tfaEnforcedGroups">[[passkeys:admin.force_2fa.help]]</label>
							<select class="form-select" id="tfaEnforcedGroups" name="tfaEnforcedGroups" multiple>
								<!-- BEGIN groups -->
								<option value="{../name}">{../value}</option>
								<!-- END groups -->
							</select>
						</div>
					</div>
				</div>
			</form>
		</div>
	</div>
</div>
