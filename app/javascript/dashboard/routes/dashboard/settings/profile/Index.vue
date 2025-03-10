<template>
  <div class="columns profile--settings ">
    <form @submit.prevent="updateUser">
      <div class="small-12 row profile--settings--row">
        <div class="columns small-3 ">
          <h4 class="block-title">
            {{ $t('PROFILE_SETTINGS.FORM.PROFILE_SECTION.TITLE') }}
          </h4>
          <p>{{ $t('PROFILE_SETTINGS.FORM.PROFILE_SECTION.NOTE') }}</p>
        </div>
        <div class="columns small-9 medium-5">
          <woot-avatar-uploader
            :label="$t('PROFILE_SETTINGS.FORM.PROFILE_IMAGE.LABEL')"
            :src="avatarUrl"
            @change="handleImageUpload"
          />
          <label :class="{ error: $v.name.$error }">
            {{ $t('PROFILE_SETTINGS.FORM.NAME.LABEL') }}
            <input
              v-model="name"
              type="text"
              :placeholder="$t('PROFILE_SETTINGS.FORM.NAME.PLACEHOLDER')"
              @input="$v.name.$touch"
            />
            <span v-if="$v.name.$error" class="message">
              {{ $t('PROFILE_SETTINGS.FORM.NAME.ERROR') }}
            </span>
          </label>
          <label :class="{ error: $v.email.$error }">
            {{ $t('PROFILE_SETTINGS.FORM.EMAIL.LABEL') }}
            <input
              v-model.trim="email"
              type="email"
              :placeholder="$t('PROFILE_SETTINGS.FORM.EMAIL.PLACEHOLDER')"
              @input="$v.email.$touch"
            />
            <span v-if="$v.email.$error" class="message">
              {{ $t('PROFILE_SETTINGS.FORM.EMAIL.ERROR') }}
            </span>
          </label>
          <label>
            {{ $t('PROFILE_SETTINGS.FORM.AVAILABILITY.LABEL') }}
            <select v-model="availability">
              <option
                v-for="status in availabilityStatuses"
                :key="status.key"
                class="text-capitalize"
                :value="status.value"
              >
                {{ status.label }}
              </option>
            </select>
          </label>
        </div>
      </div>
      <div class="profile--settings--row row">
        <div class="columns small-3 ">
          <h4 class="block-title">
            {{ $t('PROFILE_SETTINGS.FORM.PASSWORD_SECTION.TITLE') }}
          </h4>
          <p>{{ $t('PROFILE_SETTINGS.FORM.PASSWORD_SECTION.NOTE') }}</p>
        </div>
        <div class="columns small-9 medium-5">
          <label :class="{ error: $v.password.$error }">
            {{ $t('PROFILE_SETTINGS.FORM.PASSWORD.LABEL') }}
            <input
              v-model.trim="password"
              type="password"
              :placeholder="$t('PROFILE_SETTINGS.FORM.PASSWORD.PLACEHOLDER')"
              @input="$v.password.$touch"
            />
            <span v-if="$v.password.$error" class="message">
              {{ $t('PROFILE_SETTINGS.FORM.PASSWORD.ERROR') }}
            </span>
          </label>
          <label :class="{ error: $v.passwordConfirmation.$error }">
            {{ $t('PROFILE_SETTINGS.FORM.PASSWORD_CONFIRMATION.LABEL') }}
            <input
              v-model.trim="passwordConfirmation"
              type="password"
              :placeholder="
                $t('PROFILE_SETTINGS.FORM.PASSWORD_CONFIRMATION.PLACEHOLDER')
              "
              @input="$v.passwordConfirmation.$touch"
            />
            <span v-if="$v.passwordConfirmation.$error" class="message">
              {{ $t('PROFILE_SETTINGS.FORM.PASSWORD_CONFIRMATION.ERROR') }}
            </span>
          </label>
        </div>
      </div>
      <notification-settings />
      <div class="profile--settings--row row">
        <div class="columns small-3 ">
          <h4 class="block-title">
            {{ $t('PROFILE_SETTINGS.FORM.ACCESS_TOKEN.TITLE') }}
          </h4>
          <p>{{ $t('PROFILE_SETTINGS.FORM.ACCESS_TOKEN.NOTE') }}</p>
        </div>
        <div class="columns small-9 medium-5">
          <woot-code :script="currentUser.access_token"></woot-code>
        </div>
      </div>
      <woot-submit-button
        class="button nice success button--fixed-right-top"
        :button-text="$t('PROFILE_SETTINGS.BTN_TEXT')"
        :loading="isUpdating"
      >
      </woot-submit-button>
    </form>
  </div>
</template>

<script>
import { required, minLength, email } from 'vuelidate/lib/validators';
import { mapGetters } from 'vuex';
import { clearCookiesOnLogout } from '../../../../store/utils/api';
import NotificationSettings from './NotificationSettings';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  components: {
    NotificationSettings,
  },
  mixin: [alertMixin],
  data() {
    return {
      avatarFile: '',
      avatarUrl: '',
      name: '',
      email: '',
      password: '',
      passwordConfirmation: '',
      availability: 'online',
      isUpdating: false,
      availabilityStatuses: this.$t(
        'PROFILE_SETTINGS.FORM.AVAILABILITY.STATUSES_LIST'
      ),
    };
  },
  validations: {
    name: {
      required,
    },
    email: {
      required,
      email,
    },
    password: {
      minLength: minLength(6),
    },
    passwordConfirmation: {
      minLength: minLength(6),
      isEqPassword(value) {
        if (value !== this.password) {
          return false;
        }
        return true;
      },
    },
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
      currentUserId: 'getCurrentUserID',
      currentAvailabilityStatus: 'getCurrentUserAvailabilityStatus',
    }),
  },
  watch: {
    currentUserId(newCurrentUserId, prevCurrentUserId) {
      if (prevCurrentUserId !== newCurrentUserId) {
        this.initializeUser();
      }
    },
    currentAvailabilityStatus(newStatus, oldStatus) {
      if (newStatus !== oldStatus) {
        this.availability = newStatus;
      }
    },
  },
  mounted() {
    if (this.currentUserId) {
      this.initializeUser();
    }
  },
  methods: {
    initializeUser() {
      this.name = this.currentUser.name;
      this.email = this.currentUser.email;
      this.avatarUrl = this.currentUser.avatar_url;
      this.availability = this.currentUser.availability_status;
    },
    async updateUser() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        this.showAlert(this.$t('PROFILE_SETTINGS.FORM.ERROR'));
        return;
      }
      this.isUpdating = true;
      const hasEmailChanged = this.currentUser.email !== this.email;
      try {
        await this.$store.dispatch('updateProfile', {
          name: this.name,
          email: this.email,
          avatar: this.avatarFile,
          password: this.password,
          availability: this.availability,
          password_confirmation: this.passwordConfirmation,
        });
        this.isUpdating = false;
        if (hasEmailChanged) {
          clearCookiesOnLogout();
          this.showAlert(this.$t('PROFILE_SETTINGS.AFTER_EMAIL_CHANGED'));
        }
      } catch (error) {
        this.isUpdating = false;
      }
    },
    handleImageUpload({ file, url }) {
      this.avatarFile = file;
      this.avatarUrl = url;
    },
  },
};
</script>

<style lang="scss">
@import '~dashboard/assets/scss/variables.scss';
@import '~dashboard/assets/scss/mixins.scss';

.profile--settings {
  padding: 24px;
  overflow: auto;
}

.profile--settings--row {
  @include border-normal-bottom;
  padding: $space-normal;
  .small-3 {
    padding: $space-normal $space-medium $space-normal 0;
  }
  .small-9 {
    padding: $space-normal;
  }
}
</style>
